import { afterEach, describe, expect, test } from "bun:test";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import hashline from "./index";

const temporaryDirectories: string[] = [];
afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((path) => rm(path, { recursive: true })));
});

describe("hashline extension", () => {
  test("registers anchored read and write tools", async () => {
    const tools: Array<Record<string, any>> = [];
    hashline({ registerTool: (tool: Record<string, any>) => tools.push(tool) } as any);
    expect(tools.map((tool) => tool.name)).toEqual(["hashline_read", "hashline_write"]);

    const directory = await mkdtemp(join(tmpdir(), "hashline-test-"));
    temporaryDirectories.push(directory);
    await writeFile(join(directory, "sample.txt"), "first\nsecond\n");

    const output = await tools[0]!.execute("call-1", { path: "sample.txt" }, undefined, undefined, {
      cwd: directory,
    });
    expect(output.content[0].text).toMatch(/^\[sample\.txt#[A-Za-z0-9_-]+\]/);
    expect(output.content[0].text).toContain("first");
    expect(output.details.path).toBe("sample.txt");
  });

  test("documents native hashline operations instead of unified diffs", () => {
    const tools: Array<Record<string, any>> = [];
    hashline({ registerTool: (tool: Record<string, any>) => tools.push(tool) } as any);
    expect(tools[1]!.description).toContain("SWAP");
    expect(tools[1]!.promptGuidelines.join(" ")).toContain("never use unified-diff");
  });
});
