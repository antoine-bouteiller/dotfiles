---
name: create-plan
description: Research a task and write a phased plan to .plan/<slug>.md without implementing it. Use when the user wants to plan a feature or change before building, asks to "make a plan", or when a task is large enough to design before touching code. Replaces built-in plan mode.
---

# Create a plan

Produce an implementation-ready plan and stop before implementing. You are designing, not building.

Plans mirror the document shape at `~/.claude/skills/writing-spec/SKILL.md` (also
`~/.agents/skills/writing-spec/SKILL.md`). Read it before writing: it defines the frontmatter, the
`## Problem`, `## Scope`, `## Context`, `## Decisions`, `## Assumptions`, `## Constraints`,
`## Open questions`, and `## Log` sections, the `PREFIX-NNN` ID form and discipline, and the
gate-before-handoff rule. This skill covers the process and the ways a plan differs from a spec.

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

Write `.plan/<slug>.md` using the mirrored shape plus the plan-specific sections below. Use the single-file
shape by default and split only when independently verifiable phases contain too much detail for one readable
file. Write status as `draft` until the readiness gate passes. Done when a reader could execute every task
without asking for missing detail.

## 5. Validate readiness

Apply the readiness gate below to the written plan. Fix every failure before handoff, then change status to
`ready` and append that event to the log. Do not hand off a plan with unresolved material questions.

## 6. Hand off

Report the plan path, acceptance summary, ordered task list, and verification commands. Do not implement — that
is `implement-plan`'s job. Done when the user has a `ready` plan and knows how to execute and verify it.

## Plan file format

Everything the format skill defines carries over unchanged. This section records only the differences.

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

### Differences from the spec shape

- **Status vocabulary:** `draft | ready | in-progress | blocked | done`, in place of the spec's.
- **Section order:** frontmatter, `## Problem`, `## Scope`, `## Context`, `## Acceptance criteria`,
  `## Implementation`, `## Final verification`, `## Decisions`, `## Assumptions`, `## Constraints`,
  `## Open questions`, `## Log`. The three plan-specific sections take the slot where a spec carries its
  requirements; the spec's requirement-bearing sections do not appear.
- **`## Problem`** states the required outcome and why it matters, with `G-001` goals — same shape as a spec's.
- **`## Context`** omits `Actors` and carries `Current behavior` with `path:line` evidence, including affected
  callers and interfaces.
- **ID namespaces:** `AC-001` for acceptance criteria and `T-001` for tasks, on top of the shared `G-001`,
  `NG-001`, and `KD-001`. A plan's `KD` records are implementation decisions rather than product ones.
- **`related:`** names the spec this plan implements, when there is one.
- A plan records **how**, so the format skill's "never how" rule does not apply here.

### Plan-specific sections

```markdown
## Acceptance criteria

- [ ] **AC-001:** <observable, testable outcome>
- [ ] **AC-002:** <observable, testable outcome>

## Implementation

### Phase 1 — <independently verifiable outcome>

**Phase dependencies:** None | <earlier phase names>

- [ ] **T-001** <optional `[P]` marker> <imperative task with one checkable outcome>
  - **Acceptance:** AC-001
  - **Dependencies:** None | T-NNN, ...
  - **Paths:** <exact repository-relative paths; mark new paths `new`>
  - **Change:** <specific symbols/sections and behavior to add, alter, or remove>
  - **Preserve:** <important behavior or `None`>
  - **Verify:** `<runnable command or concrete manual scenario>`
  - **Expected:** <observable success result>

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>
```

### Folder shape

`index.md` follows the same schema and is the only status and checkbox authority. Its `## Implementation`
collapses each task to one line pointing at the phase file that carries the detail:

```markdown
- [ ] **T-001** <optional `[P]` marker> <task outcome; satisfies AC-001> — see `01-phase.md#t-001-task-title`
```

Each phase file contains task blocks in the shape above but no status or checkboxes:

```markdown
# Phase 1 — <independently verifiable outcome>

**Plan:** `index.md`
**Phase dependencies:** None | <earlier phase names>

## T-001 — <task title>

- **Acceptance:** AC-001
- ... (remaining task fields as above)
```

Task IDs are globally unique across phase files, and each block has exactly one matching `index.md` entry.

### Rules

- New plans begin as `draft`; handoff is allowed only after the readiness gate passes and status becomes
  `ready`. Before implementation begins, change status to `in-progress`. Log the reason for every `blocked`
  transition. Change status to `done` only after every task and acceptance criterion is checked and final
  verification succeeds.
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
- Final verification covers every `AC-NNN` ID. Build-only checks are insufficient when runtime or user-visible
  behavior is affected.
- Single-file plans remain the default. In a folder plan, split only at independently verifiable phase
  boundaries; `index.md` owns mutable state and phase files never duplicate it. Every index task link resolves
  to exactly one phase task, and every phase task has exactly one matching index checkbox.
- **The plan is the state.** Tick tasks and acceptance criteria only when their stated evidence exists. Append
  every scope, decision, status, or implementation deviation to `Log`.

### Readiness gate

Before changing status from `draft` to `ready`, confirm every applicable check in the format skill's gate, plus:

- [ ] Every task names exact paths, dependencies, runnable verification, and expected results.
- [ ] Task dependencies are existing earlier tasks, never self-references, and agree with phase ordering; the
      resulting task and phase dependency graphs are acyclic.
- [ ] Every goal is served by at least one task, every acceptance criterion maps to at least one task, and
      final verification covers every acceptance criterion, including runtime or user-visible checks where
      applicable.
- [ ] Every `[P]` task is free of incomplete dependencies and write-path conflicts.
- [ ] In a folder plan, every index task link and phase task block have exactly one matching counterpart.
- [ ] Every existing-code reference resolves, and each new path is labeled and attached to an existing owner.
- [ ] New dependencies, abstractions, and layers are necessary and justified.

If any check fails, keep status `draft` or mark it `blocked`, resolve the issue, and rerun the gate. Change
status to `ready` only when every check passes.
