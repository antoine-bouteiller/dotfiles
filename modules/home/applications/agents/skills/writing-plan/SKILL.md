---
name: writing-plan
description: Create or update a concrete implementation plan with ordered tasks, acceptance criteria, and runnable validation when planning is requested or substantial work needs coordination.
---

# Write an implementation plan

Record how to deliver the requested change: ordered tasks, preserved contracts, and evidence of
completion. A plan translates settled design into execution; it is not a second design document.
When a spec exists, reference its outcomes, contracts, and acceptance criteria instead of redefining
them. Without a spec, record the necessary design and criteria here; do not create a separate
spec merely to satisfy the format.

For a plan-only request, deliver the plan and stop. When planning supports an already authorized
implementation, finish the plan and continue that work. Preserve the user's chosen output path;
otherwise use `.plan/<slug>.md`. Plans stay out of commits unless requested.

## Ground the plan

Read the request, applicable instructions, relevant code and callers, tests, and existing design.
Identify outcomes, scope, constraints, and material unknowns. Inspect the concrete paths and
interfaces rather than inventing them. Resolve factual unknowns through inspection or bounded
experiments within the task's authorization; make remaining research a task or blocker, not a
request for the user to do the investigation. Ask only about choices requiring human judgment
that materially change scope,
architecture, data, security, or verification. Reuse prior decisions; document reasonable routine
assumptions without demanding confirmation for each one.

Define acceptance criteria as observable behavior or inspectable artifacts. Map spec-backed criteria
to their source file and ID, then to tasks and final verification. Choose the narrowest correct
change and record consequential execution choices. Reference enough contract detail to implement
correctly while leaving incidental implementation choices open. If planning exposes a design gap,
resolve it at its source within the user's authorization; do not silently change the contract in
a task.

Derive task order from required contracts, actual prerequisites, and overlapping write paths. Keep
technical dependencies distinct from an explicit delivery priority; independent work needs no
invented sequence.

## Write or amend

Read [PLAN-FORMAT.md](PLAN-FORMAT.md) for the schema, readable task layout, and a task example. Use the
single-file shape by default. For independently verifiable phases too detailed for one readable
file, read [FOLDER-PLANS.md](FOLDER-PLANS.md); its index owns all mutable state.

Give each task a heading and a short outcome explanation. Keep behavior bullets, file paths, and
verification in separate blocks rather than a nested field list. Each task retains its acceptance
links, dependencies, required behavior and invariants, and a command or concrete manual scenario
with an expected result. Scale the layout down for simple tasks. Reference existing authoritative
contracts rather than copying them; without a spec, define necessary contracts in the plan. Include
a compact signature, payload, or pseudocode example when it resolves ambiguity; keep full
implementations in code. For difficult structure or flow, consult the `choosing-visuals` skill.

New plans start as `draft`. When amending, read the current plan and affected implementation,
preserve IDs, append new ones, and record material changes in `Log`. Reopen tasks or criteria whose
prior evidence no longer covers the revised requirement. Reassess readiness and recompute affected
task order and coverage when the source design, scope, or dependencies change; do not reset
completed work unrelated to the amendment.

## Check readiness

Before marking the plan `ready`, check:

- Every goal has tasks, every acceptance criterion maps to a task and final verification, and
  required outcomes have no unresolved material design question. Spec-backed coverage agrees with
  the current source outcomes, contracts, and criteria within the plan's declared scope.
- Existing paths resolve; new paths name their owning module. Task details describe real contracts,
  dependencies, and observable success rather than placeholders.
- Dependencies exist and are acyclic. Parallel tasks have no dependency on each other and no
  conflicting write paths or interface assumptions.
- Verification exercises the affected behavior; build-only checks do not establish runtime behavior.
- IDs and references resolve. Folder plans have one index entry per task detail block.
- Decisions and assumptions are recorded; new dependencies or abstractions have a concrete benefit.

Keep an unresolved plan `draft`, or mark it `blocked` with the specific obstacle. For a plan already
in progress, preserve that status when its remaining work is ready; use `blocked` only for an actual
blocker. Readiness does not erase execution progress.

## Handoff and execution state

Report the path, intended outcome, material decisions, and verification for a plan-only request.
For implementation, the `implement` skill executes tasks and groups authorized commits
by coherent intent; task boundaries do not dictate commit boundaries.

Set `in-progress` when execution starts. Tick tasks and criteria when their evidence exists,
record important deviations in `Log`, and reconcile state with the worktree after interruptions.
Set `done` only after acceptance, final verification, and review—including verification of resulting
fixes—are complete. Avoid companion research/progress files when the plan already holds that state.
