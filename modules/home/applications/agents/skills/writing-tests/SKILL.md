---
name: writing-tests
description: Write or change tests test-first using red-green-refactor, gating each new test on the regression it catches. Also audit existing tests for low-value, duplicative, or implementation-coupled cases when the user requests a test audit or cleanup.
---

# Writing tests

Work in vertical slices: one observable behavior, a failing test, enough implementation to pass,
then refactoring while green. To audit or prune existing tests instead, read [audit.md](audit.md).

## Choose the boundary

Test the contract callers depend on, at the narrowest stable boundary that demonstrates the
behavior. Reuse boundaries agreed in the request or plan and those established by repository tests.
Read relevant domain docs such as `CONTEXT.md` and ADRs when available. Ask only when a material
interface or scope choice cannot be inferred; established boundaries need no fresh confirmation.

For interface design, inspect ownership, consumers, and existing adapters. Keep implementation
details private unless they are themselves the contract being developed.

## Gate each new test

Before adding a test, answer these; a missing answer means do not add it yet:

1. What observable behavior, invariant, or independent contract does it protect?
2. What credible regression makes it fail?
3. Why does existing coverage not already catch that failure? Each contract has one primary test
   owner at the strongest boundary; another layer needs its own distinct risk, such as a transport
   or lifecycle failure the owner cannot reach. Prefer extending a table-driven case or shared
   fixture over a near-duplicate test.
4. Does it need a production seam (export, flag, wrapper, injection hook) that no production
   caller needs? If so, test at the real boundary instead.

Then check it against the [junk patterns](tests.md#junk-patterns). A test that would break under a
behavior-preserving refactor asserts implementation; rewrite it at the owning boundary.

A bug regression test must fail on the pre-fix code for the intended reason and pass after the
fix at the owner boundary. One regression there covers the bug; do not replay the same scenario at
every layer it crosses.

## Run the loop

1. **Red.** Write one test for the next required behavior. Run it and confirm it fails for the
   intended missing behavior, not a setup, syntax, or dependency error.
2. **Green.** Implement enough to satisfy that behavior and run the relevant tests.
3. **Refactor.** Improve duplication, naming, or structure where useful, keeping tests green.
   Stay within the current scope; refactoring does not require a separate review workflow.
4. Repeat for the next behavior. Broaden verification when integration or shared contracts require it.

Tests should observe results through a suitable interface and remain useful through internal
refactors. Choose independent expected values or invariants; duplicating production logic in the
assertion weakens its ability to catch mistakes. Avoid speculative batches of tests for interfaces
that the first implementation slice may change.

Read [tests.md](tests.md) when choosing assertions and [mocking.md](mocking.md) when choosing test
doubles. Review is a later check on the result, not a replacement for refactoring while green.
