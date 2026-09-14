# Review prompts

Use the relevant prompts to investigate the actual stack and contracts. A category does not
determine severity, and a checklist item alone is not evidence of a defect.

## Security

Trace untrusted input to sensitive operations and verify protections at each boundary:

- **SQL injection:** parameterized values; identifiers handled with the query library's safe identifier API or a strict allowlist; no untrusted string interpolation.
- **Command and code injection:** safe process arguments; shell, template, dynamic evaluation, and HTML/URL escaping appropriate to the destination context.
- **Path traversal and uploads:** destination containment, symlink escape, file type/size limits, and unintended access outside allowed directories.
- **Credentials and privacy:** secrets or sensitive data committed, stored insecurely, logged, serialized, bundled, or exposed in URLs; missing redaction and excessive response fields.
- **Deserialization:** untrusted input selecting arbitrary types or executing code; unsafe parsing and missing type restrictions.
- **Network security:** TLS certificate/host verification, sensitive plaintext traffic, SSRF including redirects, and origin/CORS policies exposing credentials.
- **Authentication and authorization:** server-side authentication, role/ownership/tenant checks on every affected path, token verification, session/cookie protections, and CSRF on state changes.
- **Input validation and abuse:** external input checked at system boundaries; bounds and resource limits; attacker-controlled allocation, recursion, regex cost, or unbounded work.

## Performance

Tie findings to a reachable workload and expected data sizes or limits, rather than speculative micro-optimizations:

- **Memory and resources:** unnecessary copies and large allocations in hot paths; whole-dataset loading where streaming/pagination is needed; retained buffers and leaked connections, streams, listeners, or timers.
- **Concurrency:** blocking work on latency-sensitive execution paths, excessive contention, unbounded queues/concurrency, missing backpressure, and incomplete worker shutdown. Treat races and lost updates as correctness defects as well.
- **I/O:** repeated reads or network calls, avoidable fetch waterfalls, missing buffering/batching, and unnecessarily eager acquisition of expensive resources.
- **Algorithms and collections:** repeated scans/sorts, quadratic work at supported scale, repeated parsing or regex compilation, and data structures inappropriate to the workload.
- **Database:** N+1 queries, avoidable per-record writes, inefficient access plans, and connection/pool lifecycle problems.
- **Caching:** repeated expensive computation or token acquisition; cache scope, expiry, invalidation, and concurrent refresh behavior. Missing memoization alone is not a defect.
- **UI performance:** render/effect loops, unnecessary expensive updates, large eager bundles/lists, and layout thrashing where relevant.

## Software Architecture and Correctness

Verify behavior and consistency with the project's established patterns:

- **Requirements and logic:** supported workflows, predicates, branches, ranges, ordering, duplicates, and missing/null/empty/false/zero distinctions. Check parsing/serialization, precision, units, time boundaries, and encoding where relevant.
- **Dependency management:** existing injection/construction patterns, correct dependency lifetimes and ownership, and appropriate initialization and cleanup.
- **Configuration and models:** loader/schema conventions, validation, defaults (including omitted and blank values), serialization names, unknown-field behavior, and compatibility with existing configuration or stored data.
- **Error handling and lifecycle:** useful error context, propagation, timeout/cancellation, cleanup on success and failure, rollback/compensation, and consistent user-visible error states.
- **State and concurrency:** valid transitions, atomic check-and-act, transaction scope, partial writes, retries after side effects, idempotency, stale state, and concurrent response ordering.
- **Module organization and patterns:** correct layer and dependency direction, no accidental cycles, shared utilities reused, and public extension points placed behind the established API. Flag structural choices for concrete consequences, not personal design preference.
- **Integration and rollout:** caller contracts, registrations/routing, plugin discovery, build/deployment wiring, mixed-version compatibility, migrations, fresh installs, upgrades, and rollback where supported.
- **Tests and usability:** assertions exercise changed contracts and failure paths without mocks bypassing the behavior at risk; keyboard access, focus, labels, semantic controls, and error feedback preserve supported user workflows. Functional failures are not style nits.

## Code Style

Use repository instructions, formatter/linter configuration, and nearby conventions as the authority:

- Formatting, naming, imports, and file organization match the project; leave purely automated formatting/lint findings to existing tooling.
- Language features, type/null contracts, annotations, mutability, and documentation syntax fit the supported language version and established idioms.
- Tests follow the project's naming, structure, assertion libraries, fixture/resource layout, and isolation conventions.

Keep style findings brief and non-blocking unless they demonstrate a functional defect, which belongs in the relevant category above.

## Minor Improvements

Offer only concrete, useful, non-blocking suggestions:

- Typos, unclear names, stale comments, or missing public API documentation.
- Inappropriate log levels or unhelpful diagnostic messages.
- Test coverage for specific edge cases not already reported as defects.
- Dead code or unused parameters introduced by the change.
- Small simplifications or reuse of an existing helper; extract new abstractions only for multiple real uses.
