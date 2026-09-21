# Plan format

Use this schema when creating or substantially restructuring a plan. Keep task IDs and acceptance
links stable when amending an existing plan. Omit empty optional sections such as Decisions,
Assumptions, Constraints, and Open questions; retain meaningful existing content.

For a spec-backed plan, keep Problem and Scope to a short orientation referencing source goals and
non-goals rather than redefining them. Declare which outcomes this delivery covers, including any
intentional subset of a spec or tree. Acceptance entries map local `AC-NNN` IDs to file-qualified
source criterion IDs (for example, `AC-001` → `path/to/design.spec.md [VC-1]`); specs own their meaning,
while the plan owns coverage and completion evidence. Decisions records execution choices; design
changes belong in the source specs. Without a spec, define criteria here and record necessary
design choices in Decisions and contracts in task Behavior blocks.

````markdown
---
title: <Change name>
status: draft | ready | in-progress | blocked | done
author: <git config user.name>
date: <YYYY-MM-DD>
related: [] # repo-root-relative paths; source specs when present
---

## Problem

<one to three paragraphs: the required outcome and why it matters>

- **G-001:** <goal — the outcome that makes this change worth shipping>

## Scope

### In scope

- <observable capability this plan covers>

### Non-goals

- **NG-001:** <explicitly excluded work, and one clause on why>

## Context

- **Current behavior:** <what exists today, with `path:line` evidence, including affected callers
  and interfaces>

## Acceptance criteria

- [ ] **AC-001:** <source spec path and criterion ID with a short label, or an observable,
      testable outcome when there is no spec>

## Implementation

### Phase 1 — <independently verifiable outcome>

**Phase dependencies:** None | <earlier phase names>

#### T-001 — <task outcome>

- [ ] Complete

Requires: none or T-NNN · Covers: AC-001

<Short explanation of the intended outcome and where the change belongs.>

**Behavior**

- <required behavior>
- <important boundary or existing behavior to preserve>

**Files**

- `path/to/file` — <responsibility; mark new paths `new` and identify their owner>
- `path/to/test` — <behavior to verify>

**Verify**

```bash
<runnable verification command>
```

<Expected observable results. For manual verification, give a concrete scenario instead of a command.>

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>

## Decisions

### KD-001 — <execution choice, or design decision when there is no spec>

- **Decision:** <chosen approach>
- **Rationale:** <why>
- **Alternatives rejected:** <credible option and concrete reason; or `None`>

## Assumptions

- <reasonable default chosen because the request did not specify it, or a dependency taken as given>

## Constraints

- <external rule the change must respect; or `None`>

## Open questions

<unresolved human judgments that block execution; track investigation as tasks or blockers>

## Log

- <YYYY-MM-DD> Plan created with status `draft`.
- <YYYY-MM-DD> Readiness gate passed; status changed to `ready`.
````

IDs use `PREFIX-NNN` for goals, non-goals, acceptance criteria, tasks, and decisions. Append IDs;
do not renumber existing items. Referenced IDs must exist. Existing code uses `path:line`; label new
paths `new` and name an existing owner.

## Task readability

Give each task its own heading beneath its phase, followed by its completion checkbox and a compact
dependency/acceptance line. Lead with the intended outcome, then use Behavior, Files, and Verify
blocks as needed. Keep the task body outside the checkbox list so paragraphs and code blocks remain
easy to scan.

Combine requirements and preservation constraints under Behavior instead of repeating them across
Change, Details, and Preserve fields. Put each file on its own line, adding a responsibility when
useful. Keep verification commands beside their expected results. Reference acceptance IDs without
repeating their full definitions in each task.

Scale down for simple tasks: a short paragraph, file path, and verification can be enough beneath
the heading and tracking information. Add a compact code example beside the behavior it clarifies
only when a contract is otherwise ambiguous. Use numbered steps for ordered procedures rather than
deeply nested metadata.

Single-file plans keep one completion checkbox in each task block. Folder plans keep task checkboxes
only in the index, as described in [FOLDER-PLANS.md](FOLDER-PLANS.md).

The optional `[P]` marker on the dependency line means tasks may execute together once their dependencies are satisfied.
Tasks in the same parallel group must have disjoint write paths and compatible interfaces.
Derive dependencies from contract prerequisites and write-path conflicts; label an explicit delivery
priority as such rather than presenting it as a technical constraint.

## Task example

````markdown
#### T-002 — Add bounded retries to the sync client

- [ ] Complete

Requires: T-001 · Covers: AC-002

Transient failures should retry automatically, within a fixed attempt budget. Keep retry handling
inside `SyncClient.push`.

**Behavior**

- Attempt once, then retry at most `maxRetries` times.
- Retry `429` and `5xx` responses only where the operation's retry contract permits it.
- Honor `Retry-After` before exponential backoff.
- Preserve authentication headers and the existing `PushResult` error contract.

**Files**

- `src/sync/client.ts` — implement the retry policy using the existing clock seam.
- `src/sync/client.test.ts` — cover retry limits and failure handling.

**Verify**

```bash
npm test -- src/sync/client.test.ts
```

Retryable failures recover within the budget. Non-retryable failures return immediately.
Exhausted retries return the final error. Tests run without real delays.
````

This example assumes retries are permitted by the operation's contract. For writes, specify
idempotency or reconciliation before retrying an uncertain outcome. For migrations, describe the
compatibility and rollback boundary; for UI, show meaningful state and event transitions.
