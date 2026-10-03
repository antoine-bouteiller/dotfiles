---
name: writing-plan
description: Write or amend a temporary spec-format plan under .plan/ for a migration or evolution whose design does not warrant a durable spec.
---

# Write a plan

A plan is a spec that is not kept. Use it for migrations and evolutions — a refactor, dependency
or framework upgrade, data or API migration, or incremental change to existing behavior — whose
end state the code and any existing specs already describe once the work lands. Use the
`writing-spec` skill instead when the work establishes design truth worth keeping.

If the repository provides its own spec workflow, such as `.claude/rules/spec.md`, `/spec:*`
commands, or `*.feature.json` companions, follow it; where it conflicts with this skill, the
repository workflow wins.

## Location

Write to the user's path, otherwise `.plan/<slug>.md`; a tree goes under `.plan/<slug>/`. `.plan/`
is a local scratch folder: never commit it unless asked, and leave the file there after
implementation.

## Format and workflow

A plan follows the `writing-spec` skill exactly: read it and its
[SPEC-FORMAT.md](../writing-spec/SPEC-FORMAT.md) for frontmatter, the seven sections, identifiers,
contracts, Open Questions, decision rights, readiness passes, and lifecycle. Read
[TREES.md](../writing-spec/TREES.md) only when the plan needs a tree. Only these differ:

- **No task list.** The `implement` skill derives tasks, order, and commits from Contracts,
  Acceptance, and `module:`; a plan authoring them would be a second, drifting source of truth.
- **Contracts carry the migration.** Show the before and after shapes, the compatibility window,
  data transformation, cut-over, and rollback boundary. Acceptance proves both the new behavior
  and what must not regress; `[NG-N]` names what stays unchanged.
- **Durable specs stay authoritative.** List affected specs in `related:`. When the plan changes a
  contract a durable spec owns, amend that spec with the `writing-spec` skill in the same change;
  the plan never silently redefines it.
- **No condensing.** A plan ends at `implemented`.

Report the path, key decisions, and remaining questions. Stop before implementation unless it is
authorized; then continue with the `implement` skill.
