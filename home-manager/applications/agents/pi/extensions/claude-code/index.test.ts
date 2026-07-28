import { describe, expect, test } from "bun:test";
import { formatRulePointer, parseCommandFrontmatter, parseRuleFrontmatter } from "./index";

describe("Claude Code compatibility", () => {
  test("parses inline and list path scopes", () => {
    expect(parseRuleFrontmatter("---\npaths: [src/**, 'test/**']\n---\nRule")).toEqual({
      body: "Rule",
      paths: ["src/**", "test/**"],
    });
    expect(parseRuleFrontmatter('---\npaths:\n  - src/**\n  - "docs/**"\n---\nRule')).toEqual({
      body: "Rule",
      paths: ["src/**", "docs/**"],
    });
  });

  test("leaves rules without frontmatter untouched", () => {
    expect(parseRuleFrontmatter("Always test changes.")).toEqual({
      body: "Always test changes.",
      paths: [],
    });
  });

  test("converts command metadata and derives a fallback description", () => {
    expect(parseCommandFrontmatter("---\ndescription: 'Review this diff'\n---\nDo it")).toEqual({
      body: "Do it",
      description: "Review this diff",
    });
    expect(parseCommandFrontmatter("# Deploy safely\n\nRun checks.").description).toBe(
      "Deploy safely",
    );
  });

  test("formats scoped rule pointers", () => {
    expect(formatRulePointer("typescript.md", ["src/**/*.ts"])).toBe(
      "- .claude/rules/typescript.md — applies when working on: src/**/*.ts",
    );
  });
});
