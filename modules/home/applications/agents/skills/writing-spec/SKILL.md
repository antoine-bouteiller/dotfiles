---
name: writing-spec
description: Write or amend a design specification with intent, shipped outcomes, contracts, and acceptance criteria for a feature or architectural change.
---

# Write a design spec

Record the current design truth: why the system exists, what becomes true when it ships, and the
contracts and acceptance criteria an implementation must satisfy. Keep file edits, task breakdowns,
execution order, and runnable verification in an implementation plan, not a second design narrative.

## Ground the design

Read the request, affected code, docs, existing specs, and constraints. Identify the problem,
stakeholders, goals, and non-goals. If the problem cannot be inferred, ask what the feature solves.
Reuse established decisions and document reasonable assumptions. Resolve factual unknowns through
code, documentation, or bounded experiments within the task's authorization; ask when human
judgment is needed on scope, ownership, semantics, trade-offs, risk, or compatibility. Unavailable
evidence remains an explicit blocker, not an invented answer.

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
and preserve the repository's established format. Separate Why, Design, Outcome, Contracts, and
Acceptance: motivation, decisions, shipped consequences, system boundaries, and proof of correctness.
Derive Outcome from the resolved decisions, contracts, and acceptance criteria; do not invent scope
while summarizing. Each outcome needs acceptance evidence.

Contracts are the primary design surface: show types, payloads, signatures, invariants, and flows
directly. Add prose for rationale and constraints those representations cannot express. Stay at the
level needed to judge the architecture, not a mirror of implementation classes or function bodies.
Consult the `choosing-visuals` skill when a visual carries the contract better.

New specs start as `draft`. Amend existing specs in place, preserve IDs, append new ones, set
`status: amended`, and refresh affected outcomes and acceptance criteria. Reconcile dependent
contracts and parent/leaf specs in the same amendment. Keep durable rationale beside the decision
it explains.

Reserve Open Questions for unresolved human judgments, with the options, trade-offs, and context
needed to decide. Reuse answers already given. On resolution, absorb the answer into its decision,
contract, criterion, or constraint; repoint live references and remove the question without reusing
its ID. Report pending investigation as an evidence gap, separately from decisions the user must make.

## Review readiness

Check that:

- Goals are addressed, consequential decisions explain their rationale, and remaining questions
  and evidence gaps are explicit.
- An informed reader can say what ships. Outcomes match the current design and contracts, and each
  is demonstrated by concrete acceptance criteria; closing every question alone is not readiness.
- Design decisions and contracts agree on ownership, invariants, failure behavior,
  compatibility, and migration constraints where applicable.
- Contracts expose the actual shapes and boundaries; examples clarify difficult behavior without
  duplicating a full implementation. Acceptance checks observable behavior at the relevant surface,
  not merely the presence of source files.
- Paths and cross-links resolve; existing IDs remain stable and references are unambiguous.
- For trees, inventory, parent links, and section ownership agree.

Correct failures; if progress needs unavailable information, leave the spec draft or amended and
report that gap rather than claiming readiness. After passing, a new spec becomes `review`; an
amendment stays `amended` and is reported as ready for review. Neither implies user acceptance.
Only set `accepted` when the user explicitly accepts the design.

Report the path, key decisions, and remaining questions. For a spec-only request, stop before
implementation. If implementation is already authorized, continue with
the `writing-plan` skill when needed. Commit only when committing is authorized.
