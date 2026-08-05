---
name: create-plan
description: Research a task and write a phased plan to .plan/<slug>.md without implementing it. Use when the user wants to plan a feature or change before building, asks to "make a plan", or when a task is large enough to design before touching code. Replaces built-in plan mode.
---

# Create a plan

Produce an implementation-ready plan and stop before implementing. You are designing, not building.

## 1. Understand the task

Read the request and the code it touches. Identify the in-scope outcomes, non-goals, acceptance criteria,
constraints, assumptions, and material unknowns. Ask the user about anything that could change architecture,
scope, data, security, or verification; never silently invent it. Done when the goal and acceptance criteria
are unambiguous and every assumption is bounded and user-confirmed.

## 2. Research

Trace the current behavior end to end. Record existing code with `path:line` evidence, affected callers and
interfaces, project instructions, applicable tests and checks, and the narrowest correct change point. Done
when every task names real code and runnable verification rather than guesses.

## 3. Decide

For each non-obvious implementation choice, record `Decision / Rationale / Alternatives rejected`. Justify
every new dependency, abstraction, or layer and explain why the simpler option is insufficient. Skip ceremonial
decision records for obvious local edits. Done when an implementer does not need to choose an approach.

## 4. Write the file

Write `.plan/<slug>.md` using the applicable schema below. Use the single-file shape by default and split only
when independently verifiable phases contain too much detail for one readable file. Write status as `draft`
until the readiness gate passes. Done when a reader could execute every task without asking for missing detail.

## 5. Validate readiness

Apply the readiness gate below to the written plan. Fix every failure before handoff, then change status to
`ready` and append that event to the log. Do not hand off a plan with unresolved material questions.

## 6. Hand off

Report the plan path, acceptance summary, ordered task list, and verification commands. Do not implement — that
is `implement-plan`'s job. Done when the user has a `ready` plan and knows how to execute and verify it.

## Plan file format

The single source of truth for how plans live on disk. `implement-plan` builds on this.

### Location

Plans live in `.plan/` at the repo root, where `<slug>` is a short kebab-case name from the goal
(e.g. `add-oauth-login`). Create `.plan/` if absent. `.plan/` is a working directory, not a
deliverable — leave it out of commits unless the user says otherwise.

Two shapes:

- **Single file** — `.plan/<slug>.md`. The default; use it whenever one file remains readable.
- **Folder** — `.plan/<slug>/` with `index.md` plus one file per independently verifiable phase
  (`01-tooling.md`, …). Use only when phase detail would make one file difficult to execute. `index.md` alone
  owns status, acceptance and task checkboxes, final verification, open questions, and the log. Phase files
  own task detail and contain no mutable status or checkboxes.

Do not generate separate specs, research notes, data models, contracts, quickstarts, task files, progress JSON,
or other companion artifacts unless the user explicitly requests them.

### Single-file schema

```markdown
# <Title>

**Status:** draft | ready | in-progress | blocked | done
**Goal:** <one paragraph describing the required outcome and why it matters>

## Scope

### In scope

- <observable outcome>

### Non-goals

- <explicit exclusion or `None`>

## Context

- **Current behavior:** <what exists now, including affected callers/interfaces and `path:line` evidence>
- **Constraints:** <project rules, compatibility, security, data-loss, or platform boundaries; or `None`>
- **Assumptions:** <bounded, user-confirmed assumptions; or `None`>

## Decisions

### D001 — <decision title>

- **Decision:** <chosen approach>
- **Rationale:** <why it is the smallest correct choice>
- **Alternatives rejected:** <credible option and concrete reason; or `None` when no credible alternative exists>

## Acceptance criteria

- [ ] **AC001:** <observable, testable outcome>
- [ ] **AC002:** <observable, testable outcome>

## Implementation

### Phase 1 — <independently verifiable outcome>

**Phase dependencies:** None | <earlier phase names>

- [ ] **T001** <optional `[P]` marker> <imperative task with one checkable outcome>
  - **Acceptance:** AC001
  - **Dependencies:** None | TNNN, ...
  - **Paths:** <exact repository-relative paths; mark new paths `new`>
  - **Change:** <specific symbols/sections and behavior to add, alter, or remove>
  - **Preserve:** <important behavior or `None`>
  - **Verify:** `<runnable command or concrete manual scenario>`
  - **Expected:** <observable success result>

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>

## Open questions

<material questions that block readiness, or `None`>

## Log

- <YYYY-MM-DD> Plan created with status `draft`.
- <YYYY-MM-DD> Readiness gate passed; status changed to `ready`.
```

If no material decision needs a record, write `None.` under `## Decisions` instead of creating `D001`.

### Folder schema

`index.md` is the only status and checkbox authority:

```markdown
# <Title>

**Status:** draft | ready | in-progress | blocked | done
**Goal:** <one paragraph describing the required outcome and why it matters>

## Scope

### In scope

- <observable outcome>

### Non-goals

- <explicit exclusion or `None`>

## Context

- **Current behavior:** <what exists now, including affected callers/interfaces and `path:line` evidence>
- **Constraints:** <project rules, compatibility, security, data-loss, or platform boundaries; or `None`>
- **Assumptions:** <bounded, user-confirmed assumptions; or `None`>

## Decisions

<decision records using the single-file shape, or `None`>

## Acceptance criteria

- [ ] **AC001:** <observable, testable outcome>

## Implementation

- [ ] **T001** <optional `[P]` marker> <task outcome; satisfies AC001> — see `01-phase.md#t001-task-title`

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>

## Open questions

<material questions that block readiness, or `None`>

## Log

- <YYYY-MM-DD> Plan created with status `draft`.
- <YYYY-MM-DD> Readiness gate passed; status changed to `ready`.
```

Each linked phase file contains one or more repeatable task blocks but no status or checkboxes. Task IDs are
globally unique and each block has exactly one matching `index.md` entry:

```markdown
# Phase 1 — <independently verifiable outcome>

**Plan:** `index.md`
**Phase dependencies:** None | <earlier phase names>

## T001 — <task title>

- **Acceptance:** AC001
- **Dependencies:** None | TNNN, ...
- **Paths:** <exact repository-relative paths; mark new paths `new`>
- **Change:** <specific behavior to add, alter, or remove>
- **Preserve:** <important behavior or `None`>
- **Verify:** `<runnable command or concrete manual scenario>`
- **Expected:** <observable success result>
```

### Rules

- Required sections appear exactly once and in the shown order. Use `None` rather than deleting a required
  field or section. A folder's `index.md` and phase files each follow their complete schema above.
- New plans begin as `draft`; handoff is allowed only after the readiness gate passes and status becomes
  `ready`. Before implementation begins, change status to `in-progress`. Log the reason for every `blocked`
  transition. Change status to `done` only after every task and acceptance criterion is checked and final
  verification succeeds.
- IDs are stable and sequential within their namespace: `D001`, `AC001`, `T001`. Never renumber an existing
  ID during implementation; append new IDs and explain amendments in `Log`. Every referenced ID must exist.
- Every acceptance criterion describes observable behavior or an inspectable artifact, not an implementation
  action, and is referenced by at least one task and by final verification.
- Every task has one checkable outcome, references at least one acceptance criterion, names exact
  repository-relative paths, and includes dependencies, verification, and its expected result.
- Omit `[P]` unless a task has no incomplete dependency and its write paths do not overlap another parallel
  task. Encode shared-file and API ordering through task dependencies.
- Existing-code references use `path:line`. Label new paths `new` and identify the existing parent or module
  that will own them.
- Use code sketches only to disambiguate a contract or algorithm; do not pre-implement the solution in the plan.
- Record only decisions that materially affect implementation. Explicitly justify added dependencies,
  abstractions, or layers.
- Final verification covers every `AC` ID. Build-only checks are insufficient when runtime or user-visible
  behavior is affected.
- `Open questions` may record material blockers while status is `draft` or `blocked`, but must be `None` before
  status becomes `ready`; ask the user rather than guessing through a material unknown.
- Single-file plans remain the default. In a folder plan, split only at independently verifiable phase
  boundaries; `index.md` owns mutable state and phase files never duplicate it. Every index task link resolves
  to exactly one phase task, and every phase task has exactly one matching index checkbox.
- **The plan is the state.** Tick tasks and acceptance criteria only when their stated evidence exists. Append
  every scope, decision, status, or implementation deviation to `Log`.

### Readiness gate

Before changing status from `draft` to `ready`, confirm:

- [ ] Every required section appears exactly once and no unresolved `TODO`, `TBD`, or `NEEDS CLARIFICATION`
      placeholder remains.
- [ ] `Open questions` is `None`, and assumptions are bounded and user-confirmed.
- [ ] `D`, `AC`, and `T` IDs are stable and sequential; every referenced ID exists; and every acceptance
      criterion maps to at least one task.
- [ ] Every task names exact paths, dependencies, runnable verification, and expected results.
- [ ] Task dependencies are existing earlier tasks, never self-references, and agree with phase ordering; the
      resulting task and phase dependency graphs are acyclic.
- [ ] Final verification covers every acceptance criterion, including runtime or user-visible checks where
      applicable.
- [ ] Every `[P]` task is free of incomplete dependencies and write-path conflicts.
- [ ] In a folder plan, every index task link and phase task block have exactly one matching counterpart.
- [ ] Every existing-code reference resolves, and each new path is labeled and attached to an existing owner.
- [ ] New dependencies, abstractions, and layers are necessary and justified.

If any check fails, keep status `draft` or mark it `blocked`, resolve the issue, and rerun the gate. Change
status to `ready` only when every check passes.
