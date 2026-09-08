---
name: code-review
description: Review a merge/pull request or local changes for correctness, security, and regressions.
---

# Code Review

Find consequential defects introduced or exposed by the change. Discover broadly, then report only evidence-backed findings. Correctness and data safety take priority over design preferences and polish.

## Review process

### 1. Establish scope

- Resolve the requested MR/PR, branch, commit range, or local changes. For an MR/PR, use its actual target branch and head from `gh` / `glab`; for a branch, compare from its merge base with the intended target. Ask if the target is ambiguous rather than assuming `main`.
- For local changes, account for staged, unstaged, and relevant untracked files. Record the exact refs or working-tree scope being reviewed. Keep the checkout and user files intact; reviewing does not authorize fixes or publishing comments.
- Read the request, linked requirements when available, commits, project instructions, and stack/tooling conventions. Separate intended behavior from what the implementation currently does.
- Get the complete diff and changed-file list, including deletions, renames, tests, config, migrations, and dependency changes. Keep a working coverage list: changed file/behavior, affected callers, applicable checks, evidence, unresolved questions.
- Load every path-scoped rule (project instructions, policy files) whose glob matches a changed file before judging guard or fail-open branches; cite the rule in the finding.
- Spec and feature artifacts in the diff (`*.spec.mdx`, `*.feature.json`, verification-criteria statuses, `lastVerified` stamps) are reviewed files, not context: check their claims against the code.

Done when the review range and intended behavior are explicit and every changed file is accounted for. Missing requirements or inaccessible context remain named gaps, not assumed facts.

### 2. Trace behavior beyond the diff

- Read each changed source/config file and relevant tests, not just hunks. For large generated files, inspect the source/generator and consequential output changes; record what was not inspected.
- For each changed behavior, trace entry point → validation/authorization → transformation/state change → persistence or external effect → response/consumer. Read the relevant implementations rather than inferring behavior from names.
- Inspect every repository caller of a changed contract: signature, return value, exceptions, async behavior, serialization, defaults, or side effects. Check external consumers against available schemas/docs and compatibility guarantees. Follow changed config through its loader to its consumers; follow schema changes through writers, readers, and migrations.
- State the invariants the change must preserve (for example, tenant isolation, totals, ordering, exactly-once effects, or compatibility with stored records). Compare before and after so an unchanged caller broken by a changed helper is visible.

Done when each changed behavior has a traced caller-to-effect path and its affected contracts are checked, or a specific coverage gap is recorded.

### 3. Try to break the change

Apply the review checks below to each affected behavior. For each applicable check, construct a concrete counterexample and trace it through the code. Start with normal usage that could regress, then boundaries, failure/retry, and concurrency/lifecycle paths. Record the result in the working coverage list; an inapplicable check needs only a short reason.

Inspect what the tests actually assert, their fixtures, and mocks. Passing tests are evidence only for the paths they exercise. Look for omitted requirements, deleted safeguards, and coordinated changes that the branch forgot to make, not only suspicious added lines.

Counterexample patterns that are easy to skip:

- **Config/authoring boundary:** for every new or changed optional config field, trace the omitted and blank cases to their effect. When a fallback borrows another field's value, state what that value means on each type that inherits it. A structurally sensible default is not evidence.
- **Asymmetry:** when a guard, validator, or branch covers one of N parallel fields, paths, or sites, list the siblings and justify each absence. Treat an unused production helper that duplicates an inline default as a lead, not noise.
- **Negative space for registrations:** for each new mount, dispatch, or registration site, enumerate every place the config element can legally appear and confirm each is handled or rejected at load.
- **Falsify tests and type tests:** write the wrong case (wrong `contextType`, a throw inside a callback) and check it is actually rejected or caught. A test proves only what fails without it.

Done when every affected behavior has been checked against the applicable risk paths. Keep searching after the first finding; several symptoms may share a root cause, but independent defects still need discovery.

### 4. Independent discovery

Before sharing your candidate findings, dispatch a read-only reviewer subagent with the exact review scope, intended behavior, changed-file list, and relevant project instructions. Ask it to trace callers and failure paths and find additional correctness, security, and data-loss defects independently, with concrete evidence. Give it the review checks below, not your draft or a delete-only mandate; ask it to review directly without spawning further reviewers.

On diffs over ~100 files, split the independent review by subsystem (for example, backend validators / runtime / config+spec artifacts), one subagent per slice with that slice's counterexample list, rather than one general reviewer that overlaps your own pass.

If delegation is unavailable, make a separate caller-first pass: start from consumers, stored data, and failure paths and work back toward the changed code. Record this limitation.

Done when the independent findings or fallback pass are available for reconciliation.

### 5. Validate and reconcile

- Combine candidates by root cause. For each, identify the triggering input/state, reachable caller, faulty path, observable consequence, and how the change caused it.
- Seek disconfirming evidence: upstream validation, authorization, transaction boundaries, framework guarantees, deliberate contract changes, or tests that exercise the exact case. Read the evidence behind reviewer disagreements; neither a second opinion nor a passing suite automatically invalidates a finding.
- Run existing focused tests/checks where safe and feasible. Use a minimal non-destructive reproduction when needed; keep experiments out of the user's files and external services. A complete code-path demonstration is sufficient when execution is unavailable. Distinguish observed failures from reasoned ones.
- A spec decision authorizing a weakening is intent evidence, not impact evidence: check the spec for contradicting decisions, then rate the weakening on consequence. Report "narrower than claimed" when the MR or spec headline overstates a check.
- Keep severity unchanged when only extension or third-party code triggers the path and opening that path is the change's goal.
- When a verification criterion names a runner, confirm the pipeline actually runs it (CI config, build files). Local green is not a gate.
- Remove disproven, pre-existing, and speculative candidates using the scope rules. Retain supported defects even when the fix is large; recommend the smallest correct fix, or describe the required behavior if the remedy is uncertain.

Done when every candidate is supported, disproven, or explicitly unresolved, and every changed file in the coverage list has been reviewed or named as a gap. An unresolved potentially serious defect or a material coverage gap prevents an unqualified approval.

### 6. Report

Use the output format below. Keep the coverage list as working notes; report only findings, verification, and decision-relevant gaps.

## Scope and evidence

- Report defects introduced or made reachable by this change, including regressions in unchanged callers and missing companion edits. Anchor the finding to the changed line that causes the problem and name the affected caller; use a file-level location for a missing edit or deleted file when necessary.
- A finding needs a concrete reachable scenario and consequence. Public APIs, persisted data, and untrusted inputs are boundaries too; current internal callers alone do not establish their full input contract.
- Judge intent against requirements and established contracts. When intent is ambiguous, name the question and its impact instead of asserting a defect.
- Keep severity independent of category, confidence, and fix size. Confidence comes from evidence; severity comes from impact. Do not suppress a security, correctness, or data-loss defect because fixing it is outside the branch's planned scope.
- Prefer one finding per root cause, naming all materially affected paths. Make suggestions follow project patterns, then standard-library/platform behavior, before new abstractions or dependencies.
- Missing tests alone are not a production bug. Tie test suggestions to a concrete risk or requirement. Keep style-only suggestions brief and separate from blocking defects; leave formatter/linter-only issues to existing automation.

## Review checks

These are counterexample prompts, not automatic findings. Apply the checks relevant to the actual code and contracts.

### Correctness & data safety

- **Requirements and logic:** normal supported workflows; inverted predicates; wrong variable/field/key; missing branches; off-by-one ranges; ordering, filtering, pagination, duplicates; zero/one/many elements; missing/null/empty/false/zero distinctions.
- **Representation:** parsing and serialization round trips; overflow and precision; money rounding; units; time zones, DST, and expiry boundaries; encoding; identifier normalization; language-specific equality, coercion, and truthiness.
- **Contracts and integration:** changed arguments, return shapes, errors, sync/async behavior, defaults, and feature flags agree with all affected callers; API producers and consumers agree; registration, routing, imports, build and deployment wiring reach the new code.
- **State and concurrency:** valid state transitions; atomic check-and-act; lost updates; transaction scope; partial writes; duplicate requests and idempotency; retry after a side effect; ordering of concurrent responses; cache invalidation and stale state.
- **Failure and lifecycle:** rejection/exception propagation; timeout and cancellation; rollback/compensation; resource cleanup on success and failure; loading/error/empty UI states; unmount/dispose; stale closures and effect dependencies.
- **Compatibility and rollout:** existing stored records and old clients still work, or the break is explicitly coordinated; migrations preserve data and constraints; mixed-version deployments, fresh installs, upgrades, and rollback work where supported.

### Security

Trace untrusted input to the sensitive operation, checking existing protections at each boundary:

- **AuthN/AuthZ:** authentication and server-side role/ownership/tenant checks on every affected path; IDOR; token verification; cookie/session flags; CSRF on state changes; CORS and `postMessage` origin checks.
- **Injection:** parameterized SQL and safe identifiers; shell/command execution; templates, `eval`, dynamic imports, unsafe deserialization; unescaped HTML/attributes and dangerous URL schemes.
- **Files and network:** path traversal and symlink escape; upload type/size/destination; SSRF including redirects; TLS certificate validation and sensitive HTTP traffic.
- **Secrets and privacy:** credentials or sensitive data committed, logged, serialized, bundled, or exposed through client state/URLs; excessive response fields; missing redaction.
- **Abuse:** attacker-controlled allocation, recursion, regex cost, unbounded work, or missing limits that make a concrete denial-of-service path reachable.

### Performance & resource use

Tie findings to a reachable workload and its cost, using expected data sizes or existing limits:

- N+1 queries; repeated scans/sorts or quadratic work; large allocations in hot loops; missing batching; blocking calls in async paths; unbounded queues or concurrency; connection/stream leaks.
- Loading entire datasets/files where the supported workload needs pagination/streaming; fetch waterfalls; repeated network work; cache behavior and invalidation.
- Frontend render/effect loops; unnecessary repeated expensive work; large lists, bundles, or eager routes; layout thrash; leaked listeners, timers, and subscriptions. Unstable props or absent memoization alone are not evidence of a performance defect.

### Architecture, tests & usability

- Follow this project's layering, dependency direction, and established helpers. Flag a structural choice when it causes a concrete correctness or maintenance problem, not merely because another design is possible.
- Check whether tests exercise the changed contract and failure paths, whether assertions would catch the regression, and whether mocks bypass the behavior at risk.
- Check accessibility as functionality: keyboard reachability, focus management, semantic controls, labels, accessible names, and error feedback. A blocked user workflow is a correctness issue, not automatically a style nit.
- Check project-required localization, public documentation, and typing against the changed behavior. Optional naming, comment, and deduplication suggestions stay non-blocking.

## Severity and verdict

Assign severity by demonstrated impact, regardless of category:

- `blocker`: release cannot safely proceed; widespread outage, irreversible data loss, or comparably severe exposure on a supported path.
- `critical`: serious security breach, data corruption, or failure of a core workflow under concrete conditions.
- `major`: a supported scenario produces wrong results, fails, or suffers a material performance regression and needs correction before merge.
- `minor`: limited, non-blocking impact with a practical workaround.
- `info`: optional improvement, separate from defects.

Any supported `blocker`, `critical`, or `major` → **REQUEST CHANGES**. Only non-blocking findings → **APPROVE WITH COMMENTS**. No findings and no material gaps → **APPROVE**. If a material gap or unresolved concern prevents a decision, say **REVIEW INCOMPLETE** and name the required verification instead of inventing a finding or severity.

## Output format

```markdown
## Review: <short summary>

<Purpose and exact scope reviewed; 1–3 sentences.>

### Findings

- **[severity] Short title** — `path/to/file:line-range`
  Triggering input/state and affected caller → faulty behavior → consequence.
  Evidence: reproduction/test result or the decisive code path; distinguish inference from execution.
  Fix: smallest correct change or the invariant to restore.

### Verification and gaps

<Checks run and results; important untested paths or unavailable context; independent review or fallback.>

### Verdict

<APPROVE | APPROVE WITH COMMENTS | REQUEST CHANGES | REVIEW INCOMPLETE> — <short rationale>
```

Order findings by severity, then impact. Use precise, short line ranges. If none survive, say “No actionable findings” and report the actual verification limits. Keep optional suggestions separate; do not pad the report with empty category sections.
