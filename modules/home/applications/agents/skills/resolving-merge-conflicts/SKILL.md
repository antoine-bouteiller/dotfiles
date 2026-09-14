---
name: resolving-merge-conflicts
description: Resolve conflicts in an in-progress Git merge or rebase while preserving both change intents and unrelated work.
---

# Resolve merge conflicts

1. **Establish the operation and baseline.** Inspect status, unmerged paths, staged and unstaged
   changes, and merge/rebase metadata. Record unrelated user work before editing. Identify the
   actual base and both sides; during a rebase, Git's "ours" and "theirs" labels differ from the
   intuitive feature/target interpretation.

2. **Recover intent.** Read the conflicting code, commit messages, affected callers and tests.
   Consult linked PRs or tickets when the reason for a change remains unclear. Resolve the
   behavior, not just the conflict markers.

3. **Resolve coherently.** Preserve both intents where compatible. For incompatible behavior, use
   the stated merge goal and established contracts. If a material choice has no supported answer,
   leave that conflict unresolved and ask about that choice. Do not abort, skip commits, or invent
   a new feature as a shortcut; honor an explicit user request to abort or change the operation.

4. **Verify and stage the resolution.** Check for remaining unmerged entries and conflict markers,
   then run the relevant repository checks. Fix regressions introduced by the resolution.
   Stage only resolution-related paths or hunks. Preserve unrelated staged and unstaged content.

5. **Complete the authorized operation.** For a merge, inspect the full staged result, including
   Git's automatic merge results, before creating the merge commit. If unrelated staged work
   would be included, preserve it outside that commit using a safe index partition; ask if its
   ownership cannot be determined. For a rebase, use `git rebase --continue` and repeat for each
   conflict. After completion, verify the combined result and report any trade-offs or checks
   that could not run. A request to resolve files only stops before committing or continuing.
