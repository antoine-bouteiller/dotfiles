# Plan format

Use this shape when creating or substantially restructuring a plan. Keep task IDs and acceptance
links stable when amending an existing plan. Omit empty optional sections and retain meaningful
existing content. The outcome and scope orient the reader; tasks describe delivery, not another
design narrative.

For a spec-backed plan, name the source outcomes this delivery covers, including any intentional
subset of a spec or tree. Map local `AC-NNN` IDs to file-qualified source criteria (for example,
`AC-001` → `path/to/design.spec.mdx [VC-1]`); the spec owns their meaning, while the plan owns coverage
and completion evidence. Without a spec, define observable criteria here and include only the
contracts needed to execute the tasks. Record consequential execution choices in Decisions; design
changes belong in the source spec.

```markdown
---
title: <Change name>
status: draft | ready | in-progress | blocked | done
author: <git config user.name>
date: <YYYY-MM-DD>
related: [] # repo-root-relative paths; source specs when present
---

## Outcome

<what this delivery makes work and why; cite source spec outcomes when present>

## Scope

<what this delivery covers; note meaningful exclusions or an intentional subset of a spec>

## Acceptance criteria

- [ ] **AC-001:** <source spec path and criterion ID with a short label, or an observable,
      testable outcome when there is no spec>

## Implementation

### T-001 — <task outcome>

- [ ] Complete

Covers: AC-001

<What will work after this task, and where the change belongs.>

- **Change:** `path/to/file` — <responsibility; mark new paths `new` and identify their owner>
- **Test:** `path/to/test` — <behavior to demonstrate, when a test applies>
- **Preserve:** <existing behavior or contract that must not change, when relevant>
- **Verify:** `<command or manual scenario>` → <expected observable result>

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>

## Decisions

- **KD-001:** <consequential execution choice and why; omit when none>

## Open questions

<unresolved human judgments that block execution; track investigation as tasks or blockers>
```

IDs use `PREFIX-NNN` for acceptance criteria, tasks, and any recorded decisions. Preserve existing
IDs, including goals and non-goals in older plans; append rather than renumber. Referenced IDs must
exist. Label new paths `new` and name their owner; cite existing code with `path:line` when it
explains a non-obvious constraint. Add Context, Assumptions, or Constraints only when they change
execution; do not copy the spec's Why or Design.

## Task readability

Use a task heading and one completion checkbox, then a `Covers:` line linking its acceptance IDs.
Add `Requires: T-NNN` only for a real prerequisite. Keep the body outside the checkbox list: a short
outcome explanation followed by the affected files (including tests where appropriate), preservation
constraints, and verification with its expected result. Use multiple lines or a Behavior block for complex work;
omit empty labels and `none` placeholders. Reference spec contracts rather than repeating them.

Phases are optional: group tasks only when each phase has a distinct verifiable outcome. For phased
single-file plans, put task headings beneath the phase heading. Folder plans keep task checkboxes
only in the index, as described in [FOLDER-PLANS.md](FOLDER-PLANS.md).

Use a compact signature, payload, or pseudocode example only when a contract is otherwise ambiguous.
The optional `[P]` marker means tasks may execute together once their dependencies are satisfied;
they must have disjoint write paths and compatible interfaces. Derive dependencies from contract
prerequisites and write-path conflicts; label delivery priority separately.

## Task example

```markdown
### T-002 — Add bounded retries to the sync client

- [ ] Complete

Covers: AC-002

Recover from permitted transient failures inside `SyncClient.push`, with at most `maxRetries`
retries and honoring `Retry-After` before backoff.

- **Change:** `src/sync/client.ts` — use the existing clock seam.
- **Test:** `src/sync/client.test.ts` — cover recovery, retry limits, and immediate failure.
- **Preserve:** Authentication headers and the `PushResult` error contract; never retry
  non-retryable responses.
- **Verify:** `npm test -- src/sync/client.test.ts` → recovery stays within the budget,
  exhausted retries return the final error, and tests run without real delays.
```

This example assumes retries are permitted by the operation's contract. For writes, specify
idempotency or reconciliation before retrying an uncertain outcome. For migrations, describe the
compatibility and rollback boundary; for UI, show meaningful state and event transitions.
