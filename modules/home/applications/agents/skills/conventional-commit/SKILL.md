---
name: conventional-commit
description: Create conventional commits from staged changes, proposing a split when they contain independently useful changes.
disable-model-invocation: true
---

# Conventional commits

Commit the staged changes when committing is requested. A request for a message or proposed split
alone authorizes drafting, not committing.

## Choose commit boundaries

Read `git status --porcelain`, `git diff --cached`, `git diff`, and recent commit subjects.
Use the staged diff as the source of commit content; the unstaged diff identifies work to preserve.
If nothing is staged, report that and stop unless staging was already authorized.

One commit expresses one intent and can be reviewed or reverted on its own. Keep a behavior change
with its tests, required callers, and documentation. Split unrelated fixes, independent features,
or preparatory refactors that are useful on their own; file count alone is not a reason to split.

When a split makes sense, show the proposed ordered subjects and the files or hunks in each group,
explain the benefit briefly, and **ask whether to split before changing the index or committing**.
If the user already approved those boundaries or explicitly delegated splitting, proceed without
asking again. If they choose one commit, honor that choice.

For an approved split, preserve the original staged content and all unstaged/untracked work.
Partition only the authorized changes. With partially staged files, preserve hunk boundaries;
do not stage whole files or use a worktree-wide reset/checkout. If a safe partition is unclear,
leave the index intact and explain the exact overlap. Inspect each staged diff before committing
and verify that the sequence accounts for the original staged change without importing other work.

## Write the message

Use `type(scope): imperative summary`; scope is optional. Follow repository conventions.
Common types are `feat`, `fix`, `refactor`, `docs`, `test`, `build`, `ci`, and `chore`.
Mark breaking changes with `!` and explain the incompatible contract in a `BREAKING CHANGE:` footer.

Keep the subject concise. Add a body only for motivation, non-obvious consequences, or issue references.
Describe the resulting behavior rather than listing files. Do not add AI authorship or generation
trailers; mentioning an AI product as the subject of the change is fine.

## Commit and verify

Commit only the reviewed group. Pass multiline messages through a file or a structured argument
without shell interpolation of message content. Report each resulting hash and subject.

If a hook fails, inspect the failure and any hook-modified files. Fix and retry only when that repair
is already within the authorized task; otherwise report the failure and the remaining staged state.
Never bypass hooks or suppress checks to force a commit. Retry after a concrete correction, not
repeatedly after the same unexplained failure. Finish by checking status and preserving remaining work.
