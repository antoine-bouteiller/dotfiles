---
name: writing-tests
description: Develop features or fixes test-first using red-green-refactor when the user requests TDD or the agreed implementation workflow calls for it.
---

# Writing tests

Work in vertical slices: one observable behavior, a failing test, enough implementation to pass,
then refactoring while green.

## Choose the boundary

Test the contract callers depend on, at the narrowest stable boundary that demonstrates the
behavior. Reuse boundaries agreed in the request or plan and those established by repository tests.
Read relevant domain docs such as `CONTEXT.md` and ADRs when available. Ask only when a material
interface or scope choice cannot be inferred; established boundaries need no fresh confirmation.

For interface design, inspect ownership, consumers, and existing adapters. Keep implementation
details private unless they are themselves the contract being developed.

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
