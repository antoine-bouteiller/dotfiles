---
name: implement
description: Implement a spec or .plan/ document end to end with derived tasks, comprehensive tests, and verification.
disable-model-invocation: true
---

# Implement

The spec is the single source of truth: implement exactly what it describes, nothing beyond it.
A plan under `.plan/` uses the same format and is implemented the same way. When the document is
silent, ask; when it contradicts itself, arbitrate and record (see the precedence ladder).

If the repository provides its own spec workflow, such as `.claude/rules/spec.md`, `/spec:*`
commands, or `*.feature.json` companions, follow it; where it conflicts with this skill, the
repository workflow wins.

## 1 — Comprehend and preflight

Read the target. For a leaf, also read its umbrella read-only for design context. For an umbrella,
walk the tree: each directory's `kind: umbrella` spec is that level's umbrella. Read companion
`*.examples.*` where the spec is abstract. Collect every failure below into one report and halt
before any edit if any remains:

- Every spec in scope is `accepted`, `implementing`, or `amended`; `implemented` and `condensed`
  ones are skipped. Only the user accepts a `draft` or `review` spec.
- Open Questions are empty at every level.
- Outcome is present and every `[SO-N]` is demonstrated by a `[VC-N]`. Re-derive a stale Outcome
  rather than asking.
- Each leaf's `module:` is a real (or scaffoldable) path; leaves that may run together declare
  non-null modules. Each spec directory has exactly one umbrella.
- The toolchain works: the build and test commands resolve and a scoped build of the smallest
  in-scope module exits 0, and the tests that will carry criteria are selected by the project's
  default test invocation. Never work around a missing tool. A broken toolchain produces confident,
  committed, unverified work.

Commit pending spec edits first, as their own commit, when committing is authorized.

## Run state

Track the run in `<git-common-dir>/spec-implement/<spec-stem>.json` (`git rev-parse
--git-common-dir`), so it stays out of the worktree and is visible from every worktree. Create it
once the plan is approved and update it after every task, commit, and ladder resolution:

```json
{
  "spec": "<repo-root-relative spec path>",
  "branch": "<branch>",
  "updatedAt": "<ISO timestamp>",
  "tasks": [
    {
      "id": "T-1",
      "leaf": "<spec path>",
      "module": "<path>",
      "vc": ["VC-1"],
      "dependsOn": [],
      "status": "pending | in-progress | done | failed | blocked",
      "commit": "<sha | null>"
    }
  ],
  "criteria": {
    "VC-1": { "status": "failing | passing | deferred", "test": "<test ref>", "note": "" }
  },
  "ledger": [{ "item": "KD-2", "rung": 2, "chosen": "", "rejected": "", "lands": "file:line" }]
}
```

The file records intent; tests and the worktree record fact. Where they disagree, fact wins.

## 2 — Derive the plan

Derive ordered tasks per component or leaf: target module, files, `[VC-N]` covered, and tests to
produce. Derive order from the dependency graph, never by guessing:

- **Logical** edges from cross-leaf `[CT-N]` citations.
- **Serialization** edges from `module:` overlap; add them and say so.
- **Priority** edges only where the spec records one; honor them verbatim.

An edge-free graph means independent leaves that can run together. When the umbrella's Design
carries an execution-order table, follow its stages, gating each on its "Green when" condition
and a full build. Flag ambiguities in the plan.

Present the plan once for approval before editing; one approval covers the whole tree and the
per-component commits it lists. When the user asked for an unattended run, print the plan and
proceed: that request is the authorization, and ambiguities surface at the next batch boundary.

## 3 — Implement

Set every in-scope spec to `status: implementing`. Scaffold new modules sequentially (scaffolds
mutate shared build manifests) and verify each compiles before work starts on it. Per component:
public API → internals → wiring → configuration → tests → scoped build → simplify the changed code
→ commit. Never depend on a component not yet implemented.

**Tests.** Use the `writing-tests` skill. Two sets land with the code, in the same commit; neither
replaces the other:

- **Criterion tests:** at least one per `[VC-N]`, naming the ID in the test name or doc tag. A
  criterion that cannot be tested (manual qualification, external service) is reported as deferred
  with the reason, never claimed passing.
- **Unit tests:** the public API of every component introduced or changed: happy path, empty and
  boundary inputs, and the error paths its contracts declare. Use real dependencies for
  infrastructure unless the spec authorizes mocks.

A build with tests is the gate, never compile-only; a skipped test is a failing test.

**Delegation.** When available, dispatch one scoped worker per leaf or component; run workers
together only with disjoint modules and test files. Give each its spec path, the umbrella's
relevant `[PI]`/`[KD]`/`[SO]`, its `[VC-N]`, allowed module paths, and the facts already gathered
(build commands, module layout, existing types) so it does not rediscover them. Workers edit only
their scope, never commit, and return status, files changed, criteria covered, the verification
command with its exit code and tests-executed count, and ambiguities.

Validate evidence before accepting: treat a result as failed when the exit code is missing or
non-zero, no tests executed, or files changed outside scope. An environment fault fails the whole
batch, green siblings included. Failed work blocks only its dependents; independent work
continues. Batch surviving questions into one prompt per batch boundary, never mid-task.

## Resolving ambiguity

Spec-internal contradictions are resolved by the agent, recorded, and reviewed in one batch. Apply
in order; the first rung that resolves wins:

1. `[PI-N]` intentions beat `[KD-N]` decisions.
2. The more specific item beats the broader one: a leaf contract beats an umbrella summary; a
   named `[C-N]` beats general prose.
3. Shipped, working code beats unimplemented spec prose, when the criterion can still be satisfied.
4. An unsatisfiable `[VC-N]` is weakened, not abandoned: assert the strongest form the surface
   allows as `[VC-N.1]` with one line on why, keeping the original struck.
5. Otherwise escalate.

Record every rung 1–4 resolution: amend the spec item and add a run-state ledger row (item, rung, chosen,
rejected, `file:line` where it lands). Present the ledger once, at the end.

Escalate only when the choice changes product surface (behavior, API shape, wire format, UX), is
irreversible in code (migration, persisted format, published contract), the spec is silent on a
real decision with no `[PI-N]` implying a direction, or two defensible readings are expensive to
unwind. Anything escalated must need human judgment, not more agent work.

Decide bookkeeping without asking when the action is reversible, mechanical, and has one defensible
answer: the next free ID, a serialization edge, re-deriving Outcome, including this run's prep
edits in the first commit. Report each such decision in the summary.

Halt regardless of decision rights before: removing or weakening a build or test gate; deleting
committed files that are not this run's output; changing a shipped data schema or a public API a
shipped caller names; anything a `git revert` of the commit would not undo.

## Commits

Commit atomically per component or leaf, with its tests, following the `conventional-commit`
skill. Only the coordinating agent commits. Without commit authorization, leave verified changes
ready for review. Rewrite history only when that rewrite is authorized.

## 4 — Integrate and verify

Run the full build. Run the service or artifact where the change has runtime behavior: build green
is not runtime green. Walk every `[VC-N]` across the tree and confirm its test passes or its
deferral is recorded. Review the combined change, using the `code-review` skill for substantial
work; fix blocking findings and re-verify.

Fill each implemented `[CT-N]` anchor and set `status: implemented` only when every criterion is
covered and verification passes; otherwise keep `implementing` and report what remains. Report
per leaf: module, commit, criteria passing or deferred, and test class; then build and test totals,
auto-decisions, and the decision ledger.

## Resume and amendments

On re-invocation, read the run state. Halt if its branch differs from the current one unless the
user confirms. Reconcile with the worktree: rerun the tests of tasks marked done, reset any whose
criteria no longer pass, and resume at the first unfinished task whose dependencies are done.
Without a state file, start fresh from preflight. After a spec amendment, diff the spec, add or
reopen the affected tasks, re-run phases 3–4 for those components only, and re-verify every
criterion, original and new.

Delete the state file after the final report of a run that reached `implemented`; otherwise keep
it for resume.
