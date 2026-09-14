---
name: code-review
description: Review a merge request, pull request, commit range, or local changes for concrete defects and useful improvements.
---

# Code review

Review the requested change in context. Prioritize demonstrated impact and correctness over style.
A review alone does not authorize fixes, comments posted to a service, or an approval submitted there.

## Establish scope

Resolve the exact MR/PR, commit range, branch, or local changes. Use the actual target and head;
compare branches from their merge base. If the intended base remains ambiguous, ask. For local
changes, include staged, unstaged, and relevant untracked files unless the user narrows the scope.

Read project instructions, requirements, the complete diff and changed-file list, and relevant
tooling conventions. Account for renames, deletions, configuration, dependencies, and generated
changes. Preserve user files and the checkout.

## Trace behavior

Read enough surrounding code to understand each changed behavior, expanding to full files and
dependencies when contracts or lifecycle require it. For generated or vendored output, inspect
its source and consequential changes. Record material inspection limits.

Trace affected entry points through validation, authorization, state changes, persistence or external
effects, and consumers. Find callers of changed contracts and inspect argument, return, error,
async, default, and compatibility assumptions. State the invariants that must still hold.

Use [REVIEW-PROMPTS.md](REVIEW-PROMPTS.md) for the relevant security, performance, correctness,
architecture, style, and improvement checks. These are investigation prompts, not automatic findings.
Build concrete counterexamples from reachable inputs and states, including failure/retry and
concurrency paths where applicable. Inspect tests for assertions or mocks that bypass the behavior
at risk.

## Validate candidates

For each candidate, establish its triggering state, reachable caller, faulty path, consequence,
and connection to this change. Seek disconfirming evidence in validation, framework guarantees,
transactions, permissions, deliberate contract changes, and tests. Remove disproven, pre-existing,
and speculative candidates; keep optional improvements separate from defects.

Run focused existing checks when safe and useful. Keep reproductions isolated from user files and
external services. Distinguish observed failures from code-path reasoning; name unavailable evidence.

For substantial or risky changes, obtain an independent read-only review when delegation is
available and permitted. Supply scope, intended behavior, changed files, and project instructions
before sharing candidate findings; request no recursive delegation. Otherwise make a separate
caller-first pass when warranted. Reconcile duplicate findings by root cause.

## Report

Lead with findings ordered by severity and impact, each with:

- **Severity and short title**, anchored to the changed file and precise line.
- The triggering input/state, faulty behavior, and observable consequence.
- Evidence: a reproduction or decisive code path, labeled as observed or inferred.
- The smallest correct fix or invariant to restore.

Use a file-level location for missing edits or deleted files. Report each root cause once, naming
materially affected paths. Include optional suggestions only when they offer a concrete benefit.

Severity reflects demonstrated impact:

- **blocker:** widespread outage, irreversible data loss, or comparably severe exposure.
- **critical:** serious breach, corruption, or failure of a core workflow under concrete conditions.
- **major:** a supported scenario fails, returns wrong results, or materially regresses.
- **minor:** limited non-blocking impact with a practical workaround.
- **info:** optional improvement.

After findings, summarize scope, verification, and material gaps. If no defects were found, say so
without implying untested paths are safe. Avoid empty category sections.

Conclude with a textual verdict: **REQUEST CHANGES** for supported blocker/critical/major findings;
otherwise **REVIEW INCOMPLETE** for material gaps or unresolved concerns; **APPROVE WITH COMMENTS**
for non-blocking findings only; **APPROVE** when no findings or material gaps remain. These verdicts
are review text, not instructions to submit anything to the hosting service.
