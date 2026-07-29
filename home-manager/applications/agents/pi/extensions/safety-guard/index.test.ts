import { describe, expect, test } from "bun:test";
import safetyGuard from "./index";

type Handler = (event: any, ctx: any) => Promise<any>;

function setup() {
  let handler: Handler | undefined;
  const emitted: Array<[string, unknown]> = [];
  safetyGuard({
    on: (event: string, callback: Handler) => {
      if (event === "tool_call") handler = callback;
    },
    events: { emit: (event: string, data: unknown) => emitted.push([event, data]) },
  } as any);
  return { handler: handler!, emitted };
}

const event = (command: string) => ({ toolName: "bash", input: { command } });

describe("safety guard", () => {
  test("hard-blocks shell deletion commands and directs the agent to safe_rm", async () => {
    const { handler } = setup();
    const ctx = { cwd: "/work/project", hasUI: false };

    for (const command of [
      "rm build.log",
      "rm -rf build",
      "rmdir build",
      "unlink build.log",
      "sudo -u root rm build.log",
      "command -- rm build.log",
      `sh -c 'rm build.log'`,
      "if true; then /bin/rm build.log; fi",
      "find build -type f -delete",
      "find build -exec rm {} +",
      "printf '%s\\n' build.log | xargs rm",
    ]) {
      const result = await handler(event(command), ctx);
      expect(result.block, command).toBeTrue();
      expect(result.reason, command).toContain("safe_rm");
      expect(result.reason, command).toContain("CRITICAL");
    }
  });

  test("hard-blocks critical commands", async () => {
    const { handler } = setup();
    const result = await handler(event("mkfs /dev/sda"), { cwd: "/work/project", hasUI: false });
    expect(result.block).toBeTrue();
    expect(result.reason).toContain("CRITICAL");
  });

  test("blocks shell deletion registered for background polling", async () => {
    const { handler } = setup();
    const result = await handler(
      { toolName: "background_poll", input: { command: "rm -rf build" } },
      { cwd: "/work/project", hasUI: false },
    );
    expect(result.block).toBeTrue();
    expect(result.reason).toContain("safe_rm");
  });

  test("does not offer a confirmation prompt for shell deletion", async () => {
    const { handler } = setup();
    let confirmed = false;
    const result = await handler(event("rm build.log"), {
      cwd: "/work/project",
      hasUI: true,
      ui: {
        notify: () => undefined,
        confirm: async () => {
          confirmed = true;
          return true;
        },
      },
    });
    expect(result.reason).toContain("safe_rm");
    expect(confirmed).toBeFalse();
  });

  test("guards destructive Git, container, package, and database operations", async () => {
    const { handler } = setup();
    const ctx = { cwd: "/work/project", hasUI: false };

    for (const command of [
      "git push --force origin main",
      "docker system prune -af",
      "npm uninstall important-package",
      'psql -c "DROP TABLE users"',
    ]) {
      const result = await handler(event(command), ctx);
      expect(result.block, command).toBeTrue();
    }
  });

  test("guards protected file reads, writes, and edits", async () => {
    const { handler } = setup();
    const ctx = { cwd: "/work/project", hasUI: false };

    for (const toolName of ["read", "write", "edit"]) {
      const result = await handler({ toolName, input: { path: ".env" } }, ctx);
      expect(result.block, toolName).toBeTrue();
      expect(result.reason).toContain(`Protected file ${toolName}`);
    }

    expect(
      await handler({ toolName: "read", input: { path: ".env.example" } }, ctx),
    ).toBeUndefined();
  });

  test("never allows root deletion even in an interactive session", async () => {
    const { handler } = setup();
    let confirmed = false;
    const result = await handler(event("rm -rf /"), {
      cwd: "/work/project",
      hasUI: true,
      ui: {
        notify: () => undefined,
        confirm: async () => {
          confirmed = true;
          return true;
        },
      },
    });

    expect(result.reason).toContain("CRITICAL");
    expect(confirmed).toBeFalse();
  });

  test("reports blocked state while awaiting confirmation", async () => {
    const { handler, emitted } = setup();
    const result = await handler(event("sudo echo ok"), {
      cwd: "/work/project",
      hasUI: true,
      ui: { confirm: async () => false },
    });
    expect(result.block).toBeTrue();
    expect(emitted).toEqual([
      ["herdr:blocked", { active: true, label: "Elevated privileges (sudo)" }],
      ["herdr:blocked", { active: false }],
    ]);
  });
});
