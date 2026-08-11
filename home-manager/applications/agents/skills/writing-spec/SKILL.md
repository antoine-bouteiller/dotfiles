---
name: writing-spec
description: Shared spec-file format and specs/ conventions. Internal helper for create-spec and create-plan, not invoked on its own.
disable-model-invocation: true
hidden: true
---

# Spec file format

The single source of truth for how specs live on disk. `create-spec` writes specs to this format, and
`create-plan` mirrors its shape for plan files.

## Location

One spec, one file: `specs/<slug>.spec.md` at the repo root by default, matching an existing convention
(colocated module specs, another directory) when the repo has one. `<slug>` is kebab-case, 2–4 words, action-noun
where natural (`add-oauth-login`, `fix-payment-timeout`). Create the directory if absent.

Do not generate companion artifacts — separate checklist files, research notes, data models, contracts,
quickstarts, task lists, or progress JSON — unless the user explicitly asks. The gate below is applied, not
written to disk.

## Schema

```markdown
---
title: <Feature name>
status: draft | review | accepted | superseded
author: <git config user.name>
date: <YYYY-MM-DD>
related: [] # repo-root-relative paths to peer specs, ADRs, or docs; informational only
---

## Problem

<one to three paragraphs: the problem, who has it, what it costs today, and why now>

- **G-001:** <goal — the outcome that makes this feature worth shipping>

## Scope

### In scope

- <observable capability this spec covers>

### Non-goals

- **NG-001:** <explicitly excluded capability, and one clause on why>

## Context

- **Current behavior:** <what exists today, with `path:line` evidence for behavior this feature changes>
- **Actors:** <the user types or systems that interact with the feature>

## User stories

### US-001 — <brief title> (Priority: P1)

<the journey in plain language, from the actor's point of view>

- **Why this priority:** <the value delivered, and why it ranks here>
- **Independent test:** <how this story alone can be exercised and demonstrated>
- **Acceptance scenarios:**
  1. **Given** <initial state>, **when** <action>, **then** <observable outcome> — covers FR-001
  2. **Given** <initial state>, **when** <action>, **then** <observable outcome> — covers FR-002

### US-002 — <brief title> (Priority: P2)

<as above; each story is an independently shippable slice>

## Requirements

### Functional

- **FR-001:** The system MUST <specific, testable capability>
- **FR-002:** <actor> MUST be able to <specific, testable interaction>

### Non-functional

- **NFR-001:** <quality attribute the feature must meet — performance, security, privacy, accessibility,
  compliance — stated as an observable threshold; or `None`>

### Key entities

- **<Entity>:** <what it represents, its meaningful attributes and relationships, no storage or type detail;
  omit this section entirely when the feature involves no new data>

## Edge cases

- **EC-001:** <boundary, failure, or conflict condition> → <required behavior>

## Success criteria

- **SC-001:** <measurable, technology-agnostic outcome, with the metric that decides it>

## Decisions

### KD-001 — <product decision title>

- **Decision:** <chosen product or scope behavior>
- **Rationale:** <why, in terms of user or business value>
- **Alternatives rejected:** <credible option and concrete reason; or `None`>

## Assumptions

- <reasonable default chosen because the request did not specify it, or a dependency taken as given>

## Constraints

- <external rule the feature must respect — regulation, contract, platform, existing commitment; or `None`>

## Open questions

<material questions that block acceptance, or `None`>

## Log

- <YYYY-MM-DD> Spec created with status `draft`.
- <YYYY-MM-DD> Quality gate passed; status changed to `review`.
```

Write `None.` under `## Decisions` when no product decision needs a record. Drop `### Key entities` entirely
when the feature has no data; keep every other section, using `None` rather than deleting it.

## Rules

- **Specify what and why, never how.** No languages, frameworks, libraries, APIs, schemas, file paths for new
  code, or algorithms. A `path:line` citation of existing behavior is context; a chosen implementation is a
  plan decision. If you cannot state a requirement without naming a technology, the constraint itself is the
  requirement — say that instead.
- Write for the person who decides whether to build this, not for the person who builds it. Plain language over
  jargon.
- Required sections appear exactly once and in the shown order. IDs are stable and sequential within their
  namespace (`G-001`, `NG-001`, `US-001`, `FR-001`, `NFR-001`, `EC-001`, `SC-001`, `KD-001`). Never renumber an
  existing ID; append new ones and record the amendment in `Log`. Every referenced ID must exist.
- User stories are prioritized `P1`, `P2`, … by value, and each is independently testable — implementing `P1`
  alone must deliver something demonstrable.
- Every functional requirement is atomic, testable, and phrased with `MUST`; every one is covered by at least
  one acceptance scenario or success criterion. Every user story names at least one requirement it exercises.
- Success criteria are measurable and technology-agnostic: "checkout completes in under 3 minutes",
  "95% of searches return results within 1 second" — not "API responds in 200ms" or "the cache hit rate exceeds
  80%". Cover both quantitative outcomes and task-completion or satisfaction measures where they apply.
- Record only decisions that change product behavior or scope. Route implementation choices to the plan.
- At most three `[NEEDS CLARIFICATION]` markers, prioritized scope > security/privacy > user experience >
  detail. Everything else becomes a documented assumption. Do not ask about things with an obvious default —
  standard retention, ordinary error messaging, conventional platform behavior.
- New specs begin as `draft` and reach `review` only through the quality gate. Only the user moves a spec to
  `accepted`; mark a spec `superseded` rather than deleting it, and name its replacement in `related`.
- **Never overwrite an existing spec.** Refuse, report the existing file, and let the user choose.

## Quality gate

Before changing status from `draft` to `review`, confirm:

- [ ] Every required section appears exactly once, and no `TODO`, `TBD`, or `[NEEDS CLARIFICATION]` placeholder
      remains.
- [ ] No implementation detail leaked in: no stack, library, API, schema, or algorithm choices.
- [ ] `Open questions` is `None`, and every assumption is written down and user-confirmed where material.
- [ ] Each goal is served by at least one user story, and each user story is prioritized, independently
      testable, and carries at least one `Given/When/Then` scenario.
- [ ] Each functional requirement is atomic, testable, unambiguous, and covered by an acceptance scenario or
      success criterion; each non-functional requirement states an observable threshold.
- [ ] Each success criterion is measurable, technology-agnostic, and stated from the user's or business's point
      of view.
- [ ] Scope is bounded: non-goals are explicit, and edge cases name required behavior rather than just asking a
      question.
- [ ] IDs are stable and sequential, and every referenced ID exists.
- [ ] Every `path:line` citation resolves, and the spec is consistent with any related spec it names.

If a check fails, keep status `draft`, fix it, and rerun the gate. Change status to `review` only when every
check passes.

## Mirroring this shape in other documents

`create-plan` writes plan files rather than specs, but follows this same shape. What carries over:

- The YAML frontmatter block and its `title` / `status` / `author` / `date` / `related` fields, with the
  document's own status vocabulary.
- These sections, defined exactly as above: `## Problem` (narrative plus `G-NNN` goals), `## Scope`
  (`### In scope` plus `NG-NNN` non-goals), `## Context`, `## Decisions` (`KD-NNN` records), `## Assumptions`,
  `## Constraints`, `## Open questions`, `## Log`. A mirroring document may add fields to `## Context` or drop
  `Actors` when it has none.
- The ID form and discipline: `PREFIX-NNN`, stable, sequential within its namespace, never renumbered, every
  reference resolves, amendments recorded in `Log`. A mirroring document adds its own namespaces on top of the
  shared `G` / `NG` / `KD`.
- Required sections appear exactly once and in a fixed order; write `None` instead of deleting one. The
  document's own body sections slot in between `## Context` and `## Decisions`, where a spec puts its
  requirements.
- Gate-before-handoff: the document starts at its lowest status and advances only when every check passes;
  unresolved material questions block advancement.

What does not carry over: the requirement-bearing sections (`## User stories`, `## Requirements`,
`## Edge cases`, `## Success criteria`), the spec status vocabulary, the `specs/` location, and the
"never how" rule — a plan exists precisely to record how. The mirroring document defines its own body
sections and its own gate additions on top of this one.
