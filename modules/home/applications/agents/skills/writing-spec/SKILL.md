---
name: writing-spec
description: Write or amend a design specification that records the problem, decisions, contracts, and rationale for a feature or architectural change.
---

# Write a design spec

Record design intent: what the system does, why it has that shape, and the contracts an implementation
must satisfy. Keep task breakdowns in an implementation plan.

## Ground the design

Read the request, affected code, docs, existing specs, and constraints. Identify the problem,
stakeholders, goals, and non-goals. If the problem cannot be inferred, ask what the feature solves.
Reuse established decisions and document reasonable assumptions; ask about unresolved choices that
materially change scope, security, or user experience.

Describe the intended system in present tense. Include current behavior, compatibility requirements,
migration constraints, and before/after examples when they explain an important design decision.
An end-state description must not hide the requirements for reaching it safely.

## Choose the document

Use the path supplied by the user or the repository's convention. Otherwise colocate a module spec
as `<module-dir>/<slug>.spec.md`; use `doc/architecture/specs/<slug>.spec.md` for cross-cutting work.
Ask only when location or ownership is materially ambiguous. If a proposed new path exists, inspect
it: amend it when it is the requested spec, otherwise choose a distinct path and preserve it.

Prefer one file. Use an umbrella tree when components have substantial independent design and
readers benefit from separate ownership. Keep tightly coupled components together; line counts and
component counts are signals, not mandatory split thresholds.
Read [UMBRELLA-SPECS.md](UMBRELLA-SPECS.md) only when creating or changing such a tree.

## Draft or amend

Read [SPEC-FORMAT.md](SPEC-FORMAT.md) for the schema and contract dimensions. Use relevant sections
and preserve the repository's established format. Give every consequential decision a rationale.
Include compact types, payloads, signatures, or flow examples where prose would leave important
behavior ambiguous. Consult the `choosing-visuals` skill when a visual helps.

New specs start as `draft`. Amend existing specs in place, preserve IDs, append new ones, set
`status: amended`, and add a Changelog row stating the change, affected sections, and reason.
Reconcile dependent contracts and parent/leaf specs in the same amendment.

Put unresolved material choices in Open Questions. Present questions with the relevant options and
trade-offs, using an available question tool when useful. Reuse answers already given; leave only
questions the user defers or information that remains unavailable.

## Review readiness

Check that:

- Goals are addressed, decisions explain their rationale, and remaining questions are explicit.
- Components and detailed designs agree on ownership, contracts, invariants, failure behavior,
  compatibility, and migration constraints where applicable.
- Examples clarify non-trivial contracts without duplicating a full implementation.
- Paths and cross-links resolve; existing IDs remain stable and references are unambiguous.
- For trees, inventory, parent links, and section ownership agree.

Correct failures; if progress needs unavailable information, leave the spec draft or amended and
report that gap rather than claiming readiness. After passing, a new spec becomes `review`; an
amendment stays `amended` and is reported as ready for review. Neither implies user acceptance.
Only set `accepted` when the user explicitly accepts the design.

Report the path, key decisions, and remaining questions. For a spec-only request, stop before
implementation. If implementation is already authorized, continue with
the `writing-plan` skill when needed. Commit only when committing is authorized.
