# Audit tests

Find and remove tests that re-assert source, duplicate stronger proof, couple to implementation, or
keep test-only production seams alive. Optimize for confidence, not deletion count; prefer a few
high-confidence candidates over a large speculative inventory.

## Value bar

Tests justify their maintenance cost by protecting behavior, a credible regression, or an
independently meaningful contract. An existing test that must change for a behavior-preserving
refactor is suspect, not automatically deletable.

Before judging a candidate, read the complete test and its production owner, entry point, callers,
callees, sibling implementations, overlapping tests, CI routing, and relevant history. When the
test claims dependency-backed behavior, inspect the dependency source or types.

## Discovery

Keep discovery read-only and report evidence before editing. Hunt for the
[junk patterns](tests.md#junk-patterns). For broad scope, split discovery into parallel lanes by
area plus one cross-cutting pattern sweep when delegation is available.

## Retention bar

Keep a test that independently enforces a public API, protocol, config, migration, storage,
security, platform, default, generated cross-language, package, release, or architecture contract.
Also keep:

- call ordering when order is observable behavior;
- regressions with a credible failure mode;
- source inspection when it is the cheapest independent guard: it fails when the contract changes
  (the user-facing key, byte, or path) and survives an identifier-only refactor.

A retained test that fails on the baseline may be a product bug: reproduce it and fix the owner
rather than deleting it. Static or slow is not a deletion reason, and a test that resembles
implementation may still be the independent contract; prove otherwise before removing it.

## Candidate evidence

Record each field before editing; a missing field means the candidate is not ready for deletion:

- exact test name and location;
- what failure it can actually detect;
- non-test callers of the covered production or support seam;
- stronger remaining owner-boundary proof, or why none is needed;
- relevant history and why the test or seam exists;
- production or test-support code the deletion unlocks;
- risk and the focused validation command.

## Edit shape

Work in one coherent owner-boundary batch. Delete obsolete test-only exports, globals, wrappers,
and dead production paths instead of preserving aliases. Move retained regressions to their
canonical owners and consolidate repeated assertions into one generic contract. Prefer net-negative
production code; do not add replacement tests that restate the same implementation, or turn
uncertain candidates into cleanup to raise deletion counts.

## Validate and report

Run the owner and sibling tests, and for removed source greps run the script or dry run that owns
the real contract. Then run the repository's formatting and changed-file checks and
`git diff --check`. Continue broad audits as separate follow-up batches.

Report removed categories, production simplifications, retained false positives and why they stay,
validation actually run, production versus test line counts from `git diff --numstat`, and named
follow-ups.
