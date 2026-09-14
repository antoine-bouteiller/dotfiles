---
name: implement
description: Execute an agreed plan, spec, or set of tickets with scoped implementation, review, and verification.
disable-model-invocation: true
---

# Implement

Deliver the requested behavior, using scoped implementers and review where they improve execution.
Preserve the surrounding authorization for edits, tests, commits, and external actions.

## Frame the work

Read the target and affected code. For a plan, read linked specs and the authoritative task state,
then set `status: in-progress`. Folder plans keep state in their index. For specs or tickets, derive
ordered tasks with one checkable outcome and suitable verification each.

Resolve task dependencies, shared write paths, and contract changes before implementation. Use
the `writing-plan` skill when the work needs a durable execution plan; when
implementation is already requested, continue after planning without a new handoff approval.
Routine choices can be recorded as assumptions; ask about unresolved material scope or contract
choices.

When committing is authorized, group tasks into coherent commits by intent. Keep a contract change
with its required callers and tests. There is no target number of tasks or commits.

## Implement scoped tasks

Use one scoped implementer per substantive task when delegation is available and permitted.
Independent tasks may run concurrently only when their write paths and interfaces do not conflict.
Batch repeated mechanical edits. Work locally when delegation is unavailable or adds little value.

Give each implementer the goal, paths, relevant project instructions, required behavior and
invariants, agreed interfaces, and verification. Include enough context to make correct decisions;
avoid prescribing incidental signatures or implementation choices the design leaves open.
Implementers report the change, evidence, and concerns; they do not commit or recursively delegate.

Use the `writing-tests` skill for behavior changes where test-first development is appropriate, reusing
agreed test boundaries. Mechanical, documentation, and low-impact configuration changes need
proportionate validation rather than artificial failing tests. Use available models according to
task difficulty and environment policy; no particular model alias is required.

## Review and verify

Check both requirement satisfaction and code correctness before accepting a task. Use a fresh
reviewer for substantial or risky changes when available, passing the task, diff, and relevant
context. For small changes or without delegation, make a separate local review pass.

Inspect verification evidence. Rerun a check when the evidence is missing, stale, or insufficient,
rather than duplicating every successful run. After corrections, rerun affected checks.
Return findings to the implementer or fix them locally with the same review standard. If three
correction rounds make no progress, reassess the approach or seek an independent diagnosis;
report a concrete blocker when progress needs information or access you do not have.

## Record and commit

Tick tasks and acceptance criteria only when supported by evidence. Record deviations, important
decisions, deferred non-blocking findings, and commit hashes when applicable in the plan's `Log`.
For consequential routine decisions use `Ruling: <decision> — <reason> — <cost if wrong>`.
After interruption, reconcile the plan with the actual worktree before resuming.

If commits are authorized, stage only the intended unit and follow
the `conventional-commit` skill. Reuse previously authorized commit boundaries.
Otherwise leave verified changes ready for review. Keep plan files out of commits unless requested.
Rewrite existing history only when that rewrite is authorized; a preferred commit map is not
permission to autosquash or rebase shared work.

## Finish

Run the plan's final verification and the repository checks warranted by the change, including the
full suite when required or needed to cover shared behavior. Review the combined result, using
the `code-review` skill for substantial changes. Correct blocking findings and verify
the resulting changes before declaring completion.

Set `status: done` only when tasks, acceptance criteria, required checks, and final review are
satisfied. Otherwise record the remaining work or concrete blocker. Report the outcome, verification,
and material limitations. Continue within existing authorization; ask only for missing consequential
decisions or actions that require new permission.
