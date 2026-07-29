import { afterEach, describe, expect, test } from "bun:test";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import safeRm from "./index";

type Tool = {
  execute: (
    toolCallId: string,
    params: { paths: string[]; recursive?: boolean },
    signal: AbortSignal | undefined,
    onUpdate: undefined,
    ctx: { cwd: string },
  ) => Promise<any>;
};

const temporaryDirectories: string[] = [];
afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map((path) => rm(path, { force: true, recursive: true })),
  );
});

function setup(): Tool {
  let tool: Tool | undefined;
  safeRm({ registerTool: (definition: Tool) => (tool = definition) } as any);
  return tool!;
}

async function workspace() {
  const root = await mkdtemp(join(tmpdir(), "safe-rm-test-"));
  temporaryDirectories.push(root);
  const cwd = join(root, "project");
  await mkdir(cwd);
  return { root, cwd };
}

describe("safe rm", () => {
  test("removes literal files and explicitly recursive directories", async () => {
    const { cwd } = await workspace();
    await writeFile(join(cwd, "file.txt"), "content");
    await mkdir(join(cwd, "build"));
    await writeFile(join(cwd, "build", "output.txt"), "content");

    const result = await setup().execute(
      "call-1",
      { paths: ["file.txt", "build"], recursive: true },
      undefined,
      undefined,
      { cwd },
    );

    expect(result.details).toEqual({ removed: ["file.txt", "build"], missing: [] });
    expect(await Bun.file(join(cwd, "file.txt")).exists()).toBeFalse();
    expect(await Bun.file(join(cwd, "build", "output.txt")).exists()).toBeFalse();
  });

  test("validates every target before deleting anything", async () => {
    const { cwd } = await workspace();
    await writeFile(join(cwd, "keep.txt"), "content");

    await expect(
      setup().execute("call-2", { paths: ["keep.txt", "/etc/hosts"] }, undefined, undefined, {
        cwd,
      }),
    ).rejects.toThrow("working directory or /tmp");
    expect(await Bun.file(join(cwd, "keep.txt")).exists()).toBeTrue();
  });

  test("requires recursive intent and protects Git metadata", async () => {
    const { cwd } = await workspace();
    await mkdir(join(cwd, "build"));
    await mkdir(join(cwd, ".git"));
    await mkdir(join(cwd, "repository", ".git"), { recursive: true });

    await expect(
      setup().execute("call-3", { paths: ["build"] }, undefined, undefined, { cwd }),
    ).rejects.toThrow("recursive: true");
    await expect(
      setup().execute("call-4", { paths: [".git"], recursive: true }, undefined, undefined, {
        cwd,
      }),
    ).rejects.toThrow("Git metadata");
    await expect(
      setup().execute("call-5", { paths: ["repository"], recursive: true }, undefined, undefined, {
        cwd,
      }),
    ).rejects.toThrow("Git repository");
  });

  test("rejects paths that escape through a parent symlink", async () => {
    const { cwd } = await workspace();
    await symlink("/etc", join(cwd, "outside"));

    await expect(
      setup().execute("call-6", { paths: ["outside/hosts"] }, undefined, undefined, { cwd }),
    ).rejects.toThrow("escapes an allowed root");
  });
});
