---
name: writing-spec
description: Write or amend a design spec at <slug>.spec.md — problem, key design decisions, principles, non-goals, caveats, components, detailed design. Use when asked to spec out a feature, architecture, or technical choice, or to amend an existing spec. Precedes writing-plan.
---

# Writing a spec

Produce a spec that records **design intent**: the problem, the decisions taken and why, and the
shape of the solution. It is a committed document a future reader uses to understand the design —
not a task list. `writing-plan` turns an accepted spec into an executable plan; do not do its job.

**Editing an existing spec:** skip to step 4, amend in place per the rules below — keep IDs stable,
set `status: amended`, append a `## Changelog` row — then rerun the quality gate.

## 1. Capture the intent

Restate the feature in one paragraph: the problem, who has it, why now. If the user gave a bare
feature name with no problem behind it, ask what it solves before writing anything. Done when you
can name the goals that make this worth building.

## 2. Ground it in the repo

Read the code, docs, and existing specs the feature touches. Cite existing behavior with
`path:line`. Stay read-only. Done when the design fits the codebase that actually exists.

## 3. Resolve and confirm the path

Derive `<slug>` and resolve the location below, following the repo's convention when it has one.
**Always confirm the path with the user before writing** — inference is a guess. If the path exists,
stop and refuse to overwrite. Done when the user has approved an unused path.

## 4. Draft the spec

Write the file with `status: draft`. Fill it from what you know; record every reasonable default you
chose under `## 6. Caveats`. Put choices with no reasonable default — ones that would change scope,
security, or user experience — in `## 9. Open Questions` rather than guessing. Every `[KD-N]` gets a
rationale. Done when a reader who has never seen the codebase understands what is being built and
why it is built that way.

## 5. Resolve open questions

Present each `[OQ-N]` as one numbered question with 2–4 concrete candidate answers and the
implication of each, using `AskUserQuestion` when available. Ask them together, then fold each
answer into the relevant section. Done when only questions the user chose to defer remain.

## 6. Validate against the quality gate

Apply the gate below. Fix every failure and re-check, up to three passes; if something still fails,
leave it in `## 9. Open Questions` and say so plainly rather than declaring the spec ready. Once it
passes, set `status: review`. Done when the gate passes or the gaps are explicit.

## 7. Hand off

Report the spec path, the goals, the key design decisions, and anything still open. Recommend
`writing-plan` as the next step, and say plainly that acceptance is the user's call — you do not set
`status: accepted` yourself. Do not implement, and do not commit unless asked.

## Spec file format

### Location

One spec, one file.

- **Single-module spec** — colocate: `<module-dir>/<slug>.spec.md`.
- **Cross-cutting spec** — `doc/architecture/specs/<slug>.spec.md`, or the repo's existing spec
  directory when it has one.

`<slug>` is kebab-case, 2–4 words (`event-store`, `add-oauth-login`). Follow the repo's existing
convention over these defaults. Never overwrite an existing spec — refuse and let the user choose.

Do not generate companion artifacts (research notes, checklists, task lists, progress files) unless
the user asks. The quality gate is applied, not written to disk.

### Template

Include every section heading; write `N/A` when a section does not apply. Section 1 is the
frontmatter and needs no heading.

```markdown
---
title: <Feature or component name>
status: draft | review | accepted | implemented | amended
author: <git config user.name>
date: <YYYY-MM-DD>
related: [] # repo-root-relative paths to peer specs, ADRs, or docs; informational only
---

## 2. Problem Statement

<2–4 sentences: what problem this solves, why now, who is affected. Business context and
motivation, not implementation detail.>

- `[G-1]` <goal>
- `[G-2]` <goal>

## 3. Key Design Decisions

| Decision             | Choice         | Rationale                          |
| -------------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |

## 4. Principles & Intents

Guiding constraints that shape every subsequent detail; tiebreakers when the design is ambiguous.

- `[PI-1]` <principle — short name, then one clause of meaning>

## 5. Non-Goals

- `[NG-1]` <explicitly excluded capability>

## 6. Caveats

Known limitations, assumptions about external systems, constraints implementers must know.

- `[C-1]` <caveat>

## 7. High-Level Components

Optional diagram (Mermaid or ASCII), then the inventory:

| Component   | Module type | Responsibility | Public API surface         |
| ----------- | ----------- | -------------- | -------------------------- |
| Event Store | Java lib    | Persist events | `EventStore`, `EventQuery` |

## 8. Detailed Design

Per component in §7, whichever of these carry real content:

- **Data model / types** — records, enums, sealed hierarchies
- **API surface** — public methods, events, configuration
- **Interactions** — how it calls or is called by others
- **Error handling** — failure modes and recovery
- **Examples** — short, illustrative usage

## 9. Open Questions

- `[OQ-1]` <unresolved item needing a human decision> — owner: @name
```

### Visuals

§7 and §8 carry the design's shape; show it rather than describing it — read
`../choosing-visuals/SKILL.md` to pick the view.

### Rules

- `[PREFIX-N]` IDs are sequential within their section, starting at 1: `[G-N]` §2, `[KD-N]` §3,
  `[PI-N]` §4, `[NG-N]` §5, `[C-N]` §6, `[OQ-N]` §9. Never renumber an existing ID; append new ones,
  and sub-version amended items (`[KD-3.1]`). Every referenced ID must exist.
- Record design intent and its rationale — not implementation steps, schedules, or task breakdowns.
  Sequencing belongs in a plan (`writing-plan`).
- Every decision states a rationale. A `[KD-N]` without a reason is a defect.
- Cite existing behavior with `path:line`. Cross-links are repo-root-relative.
- Keep §8 proportionate: enough for an implementer to build the right thing, no pre-written code.
- New specs start at `draft` and reach `review` only through the quality gate. Only the user sets
  `accepted`.
- Specs are living documents — amend in place, never as a separate amendment file. Set
  `status: amended` and append a `## Changelog` row:

  ```markdown
  ## Changelog

  | Date       | Amendment         | Sections affected | Reason                             |
  | ---------- | ----------------- | ----------------- | ---------------------------------- |
  | 2026-03-15 | Add caching layer | 7, 8.3            | Performance results from load test |
  ```

- Do not invent numbered items the user did not ask for. Propose them and let the user authorize.

### Quality gate

Before moving `draft` → `review`, confirm:

- [ ] Every section heading is present, and no `TBD` or `TODO` placeholder remains outside §9.
- [ ] Every goal in §2 is addressed by something in §3–§8.
- [ ] Every `[KD-N]` states a real rationale, not a restatement of the choice.
- [ ] §7 lists every component §8 details, and §8 details every component §7 lists.
- [ ] Every `path:line` citation resolves, and every cross-link points at an existing file.
- [ ] IDs are sequential, unrenumbered, and every reference resolves.

If a check fails, stay `draft`, fix it, rerun the gate.
