# Spec format

Use this structure for a new spec when the repository has no established format. Omit empty optional
sections rather than filling a small spec with N/A; Outcome and Acceptance are needed for readiness.
When amending a legacy format, preserve its headings and IDs. Add missing outcome and acceptance
content for the affected design without requiring a whole-document migration.

```markdown
---
title: <Feature or component name>
kind: umbrella # umbrella specs only; leaves and single specs omit this field
status: draft | review | accepted | implemented | amended
author: <git config user.name>
date: <YYYY-MM-DD>
parent-spec: # repo-root-relative path to the umbrella above; omit on a top umbrella or single spec
related: [] # repo-root-relative paths to peer specs, ADRs, or docs; informational only
---

## Why

<2–4 sentences: what problem this solves, why now, who is affected. Motivation, not implementation
steps.>

- `[G-1]` <goal — why the work is worth doing>
- `[NG-1]` <explicitly excluded capability>

## Design

Intentions precede decisions: they are the tiebreakers when a choice is ambiguous.

- `[PI-1]` <principle — short name, then one clause of meaning>

| Decision             | Choice         | Rationale                          |
| -------------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |

## Outcome

- `[SO-1]` <capability, behavior, boundary, or meaningful removal that becomes true when this
  ships, derived from decisions and contracts> — demonstrated by `[VC-1]`

## Contracts

### `[CT-1]` <contract name>

<Show the type, schema, API, event, configuration, boundary, or behavioral invariant itself.
Add rationale and constraints the representation cannot express; use Contract detail below.
Link to the implementing code when it exists.>

For an umbrella, include a compact inventory linking each child spec to its owned modules and
responsibility. Cite the contracts that establish architectural dependencies; do not copy leaf
contracts here.

## Acceptance

- `[VC-1]` Given <precondition>, when <action>, then <observable result> — demonstrates `[SO-1]`

## Caveats

- `[C-1]` <known limitation, external assumption, or migration constraint>

## Open Questions

- `[OQ-1]` <unresolved human judgment> — needs: <decision context>; <options and trade-offs>
```

IDs are sequential within their prefix. Preserve existing IDs and append new ones; annotate a
superseded decision instead of silently reusing its identifier. Cross-spec references name both
the file and ID because different specs may use the same local IDs. Paths in frontmatter are
repo-root-relative.

For umbrella trees, adapt section ownership using [UMBRELLA-SPECS.md](UMBRELLA-SPECS.md).
Execution task order belongs in a plan; a spec may describe component dependencies that constrain
the design.

## Outcome and acceptance

Keep Outcome to at most seven coherent bullets, derived from resolved decisions, contracts, and
criteria. It is not a task list, file inventory, or release note. Refresh it when those sources
change. A spec ready for review must make what ships explicit, with each outcome backed by at least
one acceptance criterion and each criterion citing the outcome it demonstrates where applicable.

Acceptance defines observable correctness, including important failure and compatibility cases.
Name the test or concrete scenario that can demonstrate each criterion at the relevant surface;
the plan chooses runnable commands and task coverage. Neither implementation progress nor a build
alone proves behavioral acceptance.

## Contract detail

Show the contract directly rather than narrating an implementation. Include only dimensions that
affect the design:

- Ownership, dependency boundaries, and what remains private.
- Types, required and optional fields, defaults, serialization, and invariants.
- Public signatures, events, configuration, requests, and responses.
- State transitions, concurrency, transaction boundaries, and cancellation.
- Failure behavior, recovery, and user-visible outcomes.
- Persistence, compatibility, migrations, and rollback constraints.
- Trust boundaries, authorization, sensitive data, and necessary observability.

For a retrying write, for example, specify which outcomes are retryable, the attempt budget,
idempotency or reconciliation after uncertain results, and cancellation behavior. A signature alone
does not establish these guarantees.

Use compact code, payloads, or diagrams for the contract and its difficult branches. Explain the
responsibilities and interactions needed for architectural judgment, not every internal class.
Include current behavior where it explains compatibility; leave step-by-step implementation work
to the plan. Link to code-authoritative definitions once implemented rather than maintaining a
second full copy; preserve intent, invariants, and rationale the code does not express.

## Amendments

Amend the current design in place and refresh affected outcomes and acceptance criteria. Keep
rationale beside the item it explains when it preserves a surprising choice, external constraint,
costly-to-reverse decision, or rejected alternative likely to be reintroduced. Routine editing
history belongs in version control, not a new Changelog section.

When restructuring an existing spec, preserve IDs, live references, and durable rationale rather
than mechanically discarding legacy sections. Absorb resolved questions into the relevant items
and repoint their citations before removing them. Never reuse removed IDs. An amendment must not
imply that a previous acceptance covers the changed design.
