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

  test("hard-blocks critical commands", async () => {
    const { handler } = setup();
    const result = await handler(event("mkfs /dev/sda"), { cwd: "/work/project", hasUI: false });
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
