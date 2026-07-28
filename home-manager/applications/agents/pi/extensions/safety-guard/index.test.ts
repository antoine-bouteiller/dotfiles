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
  test("allows recursive deletion below the working directory", async () => {
    const { handler } = setup();
    expect(
      await handler(event("rm -rf build"), { cwd: "/work/project", hasUI: false }),
    ).toBeUndefined();
  });

  test("allows safe temporary cleanup before a complex shell pipeline", async () => {
    const { handler } = setup();
    const command =
      "rm -rf /tmp/e2elogs && mkdir /tmp/e2elogs; jq -r '.[]' /tmp/jobs.json | while read -r id; do echo \"$id\" & done; wait";
    expect(await handler(event(command), { cwd: "/work/project", hasUI: false })).toBeUndefined();
  });

  test("still blocks an unsafe deletion in a later complex segment", async () => {
    const { handler } = setup();
    const command = "rm -rf /tmp/e2elogs && echo ready; rm -rf ../other";
    const result = await handler(event(command), { cwd: "/work/project", hasUI: false });
    expect(result.block).toBeTrue();
  });

  test("hard-blocks critical commands", async () => {
    const { handler } = setup();
    const result = await handler(event("mkfs /dev/sda"), { cwd: "/work/project", hasUI: false });
    expect(result.block).toBeTrue();
    expect(result.reason).toContain("CRITICAL");
  });

  test("guards commands registered for background polling", async () => {
    const { handler } = setup();
    const result = await handler(
      { toolName: "background_poll", input: { command: "mkfs /dev/sda" } },
      { cwd: "/work/project", hasUI: false },
    );
    expect(result.block).toBeTrue();
    expect(result.reason).toContain("CRITICAL");
  });

  test("blocks unsafe deletion without an interactive UI", async () => {
    const { handler } = setup();
    const result = await handler(event("rm -rf ../other"), { cwd: "/work/project", hasUI: false });
    expect(result).toEqual({
      block: true,
      reason: "Recursive delete (rm -r) blocked (non-interactive mode)",
    });
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
