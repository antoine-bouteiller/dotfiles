import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { emptyGitInfoState, type GitInfoState } from "./state";

export async function fetchGitInfo(pi: ExtensionAPI): Promise<GitInfoState> {
  const [repository, branch, status] = await Promise.all([
    pi.exec("git", ["rev-parse", "--is-inside-work-tree"]),
    pi.exec("git", ["branch", "--show-current"]),
    pi.exec("git", ["status", "--short"]),
  ]);
  if (repository.code !== 0 || repository.stdout.trim() !== "true") return emptyGitInfoState();
  return {
    ...emptyGitInfoState(),
    branch: branch.stdout.trim() || null,
    changedFiles: status.stdout.trim() ? status.stdout.trim().split("\n").length : 0,
  };
}
