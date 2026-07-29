import { describe, expect, test } from "bun:test";
import { readdir } from "node:fs/promises";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import askUser from "../ask-user/index.js";
import backgroundPoll from "../background-poll/index.js";
import claudeCode from "../claude-code/index.js";
import footer from "../footer/index.js";
import hashline from "../hashline/index.js";
import herdrAgentState from "../herdr-agent-state.js";
import mcp from "../mcp/index.js";
import rtk from "../rtk.js";
import rules from "../rules/index.js";
import safeRm from "../safe-rm/index.js";
import safetyGuard from "../safety-guard/index.js";
import subagents from "../sub-agents/index.js";
import { createFakePi } from "../test-utils/fake-pi.js";

const entrypoints = {
  askUser,
  backgroundPoll,
  claudeCode,
  footer,
  hashline,
  herdrAgentState,
  mcp,
  rtk,
  rules,
  safeRm,
  safetyGuard,
  subagents,
};

describe("extension entrypoints", () => {
  test("imports every deployed extension", () => {
    for (const [name, entrypoint] of Object.entries(entrypoints)) {
      expect(entrypoint, name).toBeFunction();
    }
  });

  test("every auto-discovered module exports an extension factory", async () => {
    const root = fileURLToPath(new URL("..", import.meta.url));
    const entries = await readdir(root, { withFileTypes: true });
    const discovered = entries
      .filter((entry) => entry.isFile() && entry.name.endsWith(".ts"))
      .map((entry) => join(root, entry.name));
    for (const entry of entries.filter((candidate) => candidate.isDirectory())) {
      const children = await readdir(join(root, entry.name));
      if (children.includes("index.ts")) discovered.push(join(root, entry.name, "index.ts"));
    }

    expect(discovered.length).toBeGreaterThan(0);
    for (const path of discovered) {
      const module = (await import(pathToFileURL(path).href)) as { default?: unknown };
      expect(module.default, path).toBeFunction();
    }
  });

  test("registers the first-party tools and lifecycle handlers", () => {
    const fixture = createFakePi();
    for (const entrypoint of [
      askUser,
      backgroundPoll,
      claudeCode,
      footer,
      hashline,
      mcp,
      rules,
      safeRm,
      safetyGuard,
    ]) {
      entrypoint(fixture.pi);
    }

    expect([...fixture.state.tools.keys()].sort()).toEqual([
      "ask_user",
      "background_poll",
      "hashline_read",
      "hashline_write",
      "mcp",
      "safe_rm",
    ]);
    expect(fixture.state.handlers.has("session_start")).toBeTrue();
    expect(fixture.state.handlers.has("session_shutdown")).toBeTrue();
    expect(fixture.state.handlers.has("tool_call")).toBeTrue();
    expect(fixture.state.handlers.has("tool_result")).toBeTrue();
  });
});

describe("managed integrations", () => {
  test("rtk registers a rewrite handler and delegates command rewriting", async () => {
    const calls: Array<{ command: string; args: string[] }> = [];
    const fixture = createFakePi({
      exec: async (command, args) => {
        calls.push({ command, args });
        if (args[0] === "--version") {
          return { stdout: "rtk 0.23.0\n", stderr: "", code: 0 };
        }
        return { stdout: "rtk git status\n", stderr: "", code: 0 };
      },
    });

    await rtk(fixture.pi);
    const event = { toolName: "bash", input: { command: "git status" } };
    await fixture.emit("tool_call", event, { signal: undefined });

    expect(event.input.command).toBe("rtk git status");
    expect(calls).toEqual([
      { command: "rtk", args: ["--version"] },
      { command: "rtk", args: ["rewrite", "git status"] },
    ]);
  });

  test("herdr remains a no-op when its managed environment is disabled", async () => {
    const modulePath = fileURLToPath(new URL("../herdr-agent-state.ts", import.meta.url));
    const script = `
      const { default: extension } = await import(${JSON.stringify(modulePath)});
      extension(new Proxy({}, { get() { throw new Error("disabled integration accessed Pi"); } }));
    `;
    const child = Bun.spawn([process.execPath, "--eval", script], {
      env: {
        ...process.env,
        HERDR_ENV: "0",
        HERDR_SOCKET_PATH: "",
        HERDR_PANE_ID: "",
      },
      stdout: "pipe",
      stderr: "pipe",
    });

    const exitCode = await child.exited;
    expect(exitCode).toBe(0);
  });
});
