---
name: code-review
description: Review a merge/pull request or local changes for security, performance, architecture, correctness, style, and improvements.
---

# Code Review

Review the complete change in context, applying the five categories below in order. Derive language, framework, and style conventions from the repository rather than imposing a particular stack. Correctness and data safety are required across all categories.

## Review process

### 1. Establish scope and context

- Resolve the requested MR/PR, branch, commit range, or local changes. Use the MR/PR's actual target and head; compare branches from the merge base with the intended target. If the scope or base is ambiguous, ask rather than assuming a default branch.
- For local changes, include staged, unstaged, and relevant untracked files. Preserve the checkout and user files; a review does not authorize fixes or publishing comments.
- Read the request, available linked requirements, recent commits, project instructions (including path-scoped rules), and tooling configuration. Learn established patterns from nearby code and tests.
- Get the full diff, diff stats, and changed-file list, including deletions, renames, tests, configuration, migrations, and dependencies. Track coverage in working notes.

Done when the exact scope and intended behavior are explicit and every changed file is accounted for. Record unavailable context as a gap.

### 2. Read and trace the change

- Read every changed file in its entirety, not just diff hunks, along with relevant tests. For large generated or vendored files, inspect the source/generator and consequential output changes; record inspection limits.
- Trace each changed behavior from entry point through validation/authorization, state changes, persistence or external effects, and response/consumer.
- Inspect every repository caller of a changed contract, including arguments, return values, errors, async behavior, defaults, and side effects. Check external consumers against available schemas, documentation, and compatibility guarantees.
- Follow configuration through loaders and consumers, schemas through readers/writers and migrations, and registrations through all supported entry points. Check documentation and verification claims against implementation and CI wiring.
- State the invariants the change must preserve and compare before/after behavior, including unchanged callers that may regress.

Done when each changed behavior has a traced caller-to-effect path and its affected contracts are checked, or a specific coverage gap is recorded.

### 3. Apply the review categories

For each changed file and affected behavior, apply all relevant checks below in priority order. Construct concrete counterexamples: normal usage, omitted/blank/null/zero values, boundaries, failure/retry, and concurrency/lifecycle paths. Check sibling fields and parallel paths for missing companion changes. Continue after the first finding.

Inspect test assertions, fixtures, and mocks: would a wrong implementation fail? Passing tests establish only the behavior they exercise. Tie coverage suggestions to a concrete risk or requirement.

Done when every changed file has been checked against all applicable categories and risk paths; keep the coverage notes out of the final report.

### 4. Validate and report

- Obtain an independent read-only review with the exact scope, intended behavior, changed-file list, and project instructions before sharing candidate findings. Ask for direct review without recursive delegation. If delegation is unavailable, make a separate caller-first pass and record the limitation.
- Reconcile findings by root cause. For each defect, establish the triggering input/state, reachable caller, faulty path, observable consequence, and how this change introduced or exposed it.
- Seek disconfirming evidence in upstream validation, permissions, transaction boundaries, framework guarantees, deliberate contract changes, and tests. Distinguish intent from impact; an intended weakening can still violate another requirement or expose a serious risk.
- Run existing focused checks where safe and feasible. Keep reproductions non-destructive and outside user files and external services. When execution is unavailable, provide a decisive code-path demonstration and distinguish inference from observed failure.
- Remove disproven, pre-existing, and speculative candidates. Keep optional suggestions separate from defects. Recommend existing project helpers, standard-library or platform features, and the smallest correct fix before new abstractions or dependencies.

Done when each candidate is supported, disproven, or explicitly unresolved and every changed file is reviewed or named as a gap. Produce the report below; material gaps prevent an unqualified approval.

## Review categories (by priority)

P1–P5 indicate review order, not finding severity. These checks are prompts, not automatic findings; judge applicability against the actual stack and contracts.

### P1 — Security

Trace untrusted input to sensitive operations and verify protections at each boundary:

- **SQL injection:** parameterized values; identifiers handled with the query library's safe identifier API or a strict allowlist; no untrusted string interpolation.
- **Command and code injection:** safe process arguments; shell, template, dynamic evaluation, and HTML/URL escaping appropriate to the destination context.
- **Path traversal and uploads:** destination containment, symlink escape, file type/size limits, and unintended access outside allowed directories.
- **Credentials and privacy:** secrets or sensitive data committed, stored insecurely, logged, serialized, bundled, or exposed in URLs; missing redaction and excessive response fields.
- **Deserialization:** untrusted input selecting arbitrary types or executing code; unsafe parsing and missing type restrictions.
- **Network security:** TLS certificate/host verification, sensitive plaintext traffic, SSRF including redirects, and origin/CORS policies exposing credentials.
- **Authentication and authorization:** server-side authentication, role/ownership/tenant checks on every affected path, token verification, session/cookie protections, and CSRF on state changes.
- **Input validation and abuse:** external input checked at system boundaries; bounds and resource limits; attacker-controlled allocation, recursion, regex cost, or unbounded work.

### P2 — Performance

Tie findings to a reachable workload and expected data sizes or limits, rather than speculative micro-optimizations:

- **Memory and resources:** unnecessary copies and large allocations in hot paths; whole-dataset loading where streaming/pagination is needed; retained buffers and leaked connections, streams, listeners, or timers.
- **Concurrency:** blocking work on latency-sensitive execution paths, excessive contention, unbounded queues/concurrency, missing backpressure, and incomplete worker shutdown. Treat races and lost updates as correctness defects as well.
- **I/O:** repeated reads or network calls, avoidable fetch waterfalls, missing buffering/batching, and unnecessarily eager acquisition of expensive resources.
- **Algorithms and collections:** repeated scans/sorts, quadratic work at supported scale, repeated parsing or regex compilation, and data structures inappropriate to the workload.
- **Database:** N+1 queries, avoidable per-record writes, inefficient access plans, and connection/pool lifecycle problems.
- **Caching:** repeated expensive computation or token acquisition; cache scope, expiry, invalidation, and concurrent refresh behavior. Missing memoization alone is not a defect.
- **UI performance:** render/effect loops, unnecessary expensive updates, large eager bundles/lists, and layout thrashing where relevant.

### P3 — Software Architecture and Correctness

Verify behavior and consistency with the project's established patterns:

- **Requirements and logic:** supported workflows, predicates, branches, ranges, ordering, duplicates, and missing/null/empty/false/zero distinctions. Check parsing/serialization, precision, units, time boundaries, and encoding where relevant.
- **Dependency management:** existing injection/construction patterns, correct dependency lifetimes and ownership, and appropriate initialization and cleanup.
- **Configuration and models:** loader/schema conventions, validation, defaults (including omitted and blank values), serialization names, unknown-field behavior, and compatibility with existing configuration or stored data.
- **Error handling and lifecycle:** useful error context, propagation, timeout/cancellation, cleanup on success and failure, rollback/compensation, and consistent user-visible error states.
- **State and concurrency:** valid transitions, atomic check-and-act, transaction scope, partial writes, retries after side effects, idempotency, stale state, and concurrent response ordering.
- **Module organization and patterns:** correct layer and dependency direction, no accidental cycles, shared utilities reused, and public extension points placed behind the established API. Flag structural choices for concrete consequences, not personal design preference.
- **Integration and rollout:** caller contracts, registrations/routing, plugin discovery, build/deployment wiring, mixed-version compatibility, migrations, fresh installs, upgrades, and rollback where supported.
- **Tests and usability:** assertions exercise changed contracts and failure paths without mocks bypassing the behavior at risk; keyboard access, focus, labels, semantic controls, and error feedback preserve supported user workflows. Functional failures are not style nits.

### P4 — Code Style

Use repository instructions, formatter/linter configuration, and nearby conventions as the authority:

- Formatting, naming, imports, and file organization match the project; leave purely automated formatting/lint findings to existing tooling.
- Language features, type/null contracts, annotations, mutability, and documentation syntax fit the supported language version and established idioms.
- Tests follow the project's naming, structure, assertion libraries, fixture/resource layout, and isolation conventions.

Keep style findings brief and non-blocking unless they demonstrate a functional defect, which belongs in the relevant category above.

### P5 — Minor Improvements

Offer only concrete, useful, non-blocking suggestions:

- Typos, unclear names, stale comments, or missing public API documentation.
- Inappropriate log levels or unhelpful diagnostic messages.
- Test coverage for specific edge cases not already reported as defects.
- Dead code or unused parameters introduced by the change.
- Small simplifications or reuse of an existing helper; extract new abstractions only for multiple real uses.

## Severity and verdict

Assign severity by demonstrated impact, independent of category, confidence, or fix size:

- `blocker`: release cannot safely proceed; widespread outage, irreversible data loss, or comparably severe exposure on a supported path.
- `critical`: serious security breach, data corruption, or failure of a core workflow under concrete conditions.
- `major`: a supported scenario produces wrong results, fails, or suffers a material performance regression and needs correction before merge.
- `minor`: limited, non-blocking impact with a practical workaround.
- `info`: optional improvement.

Any supported `blocker`, `critical`, or `major` → **REQUEST CHANGES**. Otherwise, a material coverage gap or unresolved concern → **REVIEW INCOMPLETE**, naming the required verification. Only non-blocking findings → **APPROVE WITH COMMENTS**. No findings and no material gaps → **APPROVE**.

## Output format

```markdown
## Review: <short summary>

### Overview

<Purpose and exact scope reviewed; 1–3 sentences.>

### P1 — Security

<Findings or "No issues found.">

### P2 — Performance

<Findings or "No issues found.">

### P3 — Software Architecture and Correctness

<Findings or "No issues found.">

### P4 — Code Style

<Findings or "No issues found.">

### P5 — Minor Improvements

<Suggestions or "No suggestions.">

### Verification and gaps

<Checks run and results; important untested paths or unavailable context; independent review or fallback.>

### Verdict

<APPROVE | APPROVE WITH COMMENTS | REQUEST CHANGES | REVIEW INCOMPLETE> — <short rationale>
```

For each finding, use:

```markdown
- **[severity] Short title** — `path/to/file:line-range`
  Triggering input/state and affected caller → faulty behavior → consequence.
  Evidence: reproduction/test result or decisive code path; distinguish inference from execution.
  Fix: smallest correct change or the invariant to restore.
```

Order findings within each category by severity and impact. Report each root cause once, naming materially affected paths. Anchor defects to the changed line causing them; use a file-level location for a missing edit or deleted file. Optional suggestions need a concrete benefit rather than a failure scenario. Where coverage is incomplete or a category is inapplicable, say so instead of claiming no issues.
