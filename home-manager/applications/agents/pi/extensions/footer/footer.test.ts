import { describe, expect, test } from "bun:test";
import { quotaFromHeaders } from "./provider";
import { columns, formatTokens, progressBar } from "./render";
import { emptyGitInfoState, emptyModelInfoState } from "./state";

describe("footer formatting", () => {
  test("formats token counts and bounded progress bars", () => {
    expect(formatTokens(999)).toBe("999");
    expect(formatTokens(12_400)).toBe("12k");
    expect(formatTokens(1_250_000)).toBe("1.3M");
    expect(progressBar(-1, 4)).toBe("░░░░");
    expect(progressBar(150, 4)).toBe("▓▓▓▓");
  });

  test("keeps columns within the available width", () => {
    const rendered = columns("a very long branch name", "model/context", 20);
    expect(Bun.stringWidth(rendered)).toBeLessThanOrEqual(20);
  });

  test("derives Azure quota from response headers", () => {
    expect(
      quotaFromHeaders("azure-openai", {
        "x-ratelimit-limit-tokens": "1000",
        "x-ratelimit-remaining-tokens": "250",
      }),
    ).toEqual({ label: "azure", percent: 75 });
    expect(quotaFromHeaders("anthropic", {})).toBeNull();
  });

  test("creates independent empty state values", () => {
    expect(emptyModelInfoState().modelId).toBe("no-model");
    expect(emptyGitInfoState()).toEqual({ branch: null, changedFiles: 0, pullRequest: null });
  });
});
