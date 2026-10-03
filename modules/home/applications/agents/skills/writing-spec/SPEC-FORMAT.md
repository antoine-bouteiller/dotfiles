# Spec format

## Frontmatter

```yaml
---
title: <component, service, or feature name>
kind: umbrella # umbrella specs only; leaves and single specs omit it
status: draft | review | accepted | implementing | implemented | amended | condensed
author: <git config user.name>
date: <YYYY-MM-DD>
module: <repo-root-relative path> # or a list; required on a leaf or single spec owning code
related: [] # repo-root-relative paths to peer specs, ADRs, docs; informational only
---
```

`module:` is the single declaration of which code a spec owns. List every module when a concern
spans several (for example a backend type and its frontend handler): implementation serializes
work by module overlap, and an undeclared module is an invisible write race. A spec owning no code
declares `module: null` and says why. There is no `parent-spec:` field; see [TREES.md](TREES.md).

```text
draft → review → accepted → implementing → implemented → condensed
                    ↑                                       │
                    └──────────── amended ←─────────────────┘
```

## Sections

Seven sections, in this order. Omit a section with nothing to say rather than writing N/A;
`## Outcome` is required at `accepted` and later.

| Section             | Carries                                                                  | IDs               |
| ------------------- | ------------------------------------------------------------------------ | ----------------- |
| `## Why`            | Problem paragraph, goals, non-goals — what this is for                   | `[G-N]` `[NG-N]`  |
| `## Design`         | Intentions first, then decisions — how the design tends to achieve it    | `[PI-N]` `[KD-N]` |
| `## Outcome`        | What becomes true when this ships                                        | `[SO-N]`          |
| `## Contracts`      | The shapes and boundaries themselves; prose only for what they can't say | `[CT-N]`          |
| `## Acceptance`     | How correctness will be demonstrated                                     | `[VC-N]`          |
| `## Caveats`        | Known limits, external assumptions, implementer constraints              | `[C-N]`           |
| `## Open Questions` | What still needs human judgment                                          | `[OQ-N]`          |

### Why

One paragraph of problem and motivation, then goals and non-goals.

```markdown
- `[G-1]` Support 1Bn events with sub-second query latency
- `[NG-1]` Multi-region replication
```

### Design

Intentions above decisions; the order is load-bearing because `[PI-N]` are the tiebreakers when a
`[KD-N]` is ambiguous. Before implementation, a one-sentence rationale is usually correct.

```markdown
- `[PI-1]` Compute-on-write — pre-compute at ingestion, not at query time

| Decision             | Choice         | Rationale                          |
| -------------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |
```

### Outcome

Capabilities added or changed, behaviors that will exist, boundaries introduced or altered,
meaningful removals. Distinct from goals (why), contracts (shape), and acceptance (proof).

```markdown
- `[SO-1]` Every event carries a monotonic sequence number, so a reader can resume from a
  cursor instead of replaying the log. — demonstrated by `[VC-3]`
```

At most seven bullets: a coherence check, not a summary, plan, release note, or file list. Derived
from resolved `[KD]`, `[CT]`, and `[VC]`, and refreshed when they move. A bullet no `[VC]`
demonstrates is either missing a criterion or is not an outcome.

### Contracts

The primary design surface. A `[CT-N]` is a type, API, schema, event, config shape, subsystem
boundary, or behavioral invariant. Each declares a `kind` and, once implemented, a code anchor
(`null` until then); the anchor lets a condensed spec reference the code instead of copying it.

```markdown
| ID       | Kind   | Contract                                           | Anchor                          |
| -------- | ------ | -------------------------------------------------- | ------------------------------- |
| `[CT-1]` | api    | `EventStore.append(Event) -> Result<Seq, Reject>`  | `libs/…/EventStore.java#append` |
| `[CT-2]` | schema | `events(seq bigserial pk, payload jsonb not null)` | `…/V3__events.sql`              |
```

`kind` ∈ `type | api | schema | event | config | boundary | invariant`. A contract too large for a
row gets a `### [CT-N] <name>` subsection with a `Kind: … · Anchor: …` line, then the fenced shape
and only the prose it cannot carry.

Include only dimensions that affect the design: ownership and what stays private; fields, defaults,
serialization, invariants; state transitions, concurrency, transactions, cancellation; failure
behavior and recovery; persistence, compatibility, migration, rollback; trust boundaries and
sensitive data. A signature alone does not establish retry, idempotency, or cancellation guarantees.

Diagrams are semantic core here, not appendix: sequence for interaction, state for lifecycle, flow
for transformation, class for the shape of the domain model at the altitude of architectural
judgment, never mirroring every class. An umbrella's component inventory lists its children and
their `module:` values, derived from the children rather than authored independently.

A concrete walkthrough longer than ~30 lines moves to a companion `<stem>.examples.md` (same
extension as the spec) as `[EX-N]`, leaving a pointer.

### Acceptance

Concrete, testable criteria, each mapping to at least one test and citing the `[SO-N]` it
demonstrates where one applies.

```markdown
- `[VC-1]` Given X, when Y, then Z. — demonstrates `[SO-2]`
```

Assert each criterion as end-to-end as the surface allows: a real artifact, session, or harness.
Never a source-tree grep or "file contains X" proxy, and never a live LLM as a CI gate; pin a
deterministic surrogate for CI and record the live run as manual qualification.

### Caveats

```markdown
- `[C-1]` Assumes Postgres ≥ 16 — the migrator relies on `MERGE`.
```

### Open Questions

An `[OQ-N]` exists only where answering requires human judgment rather than more agent work. If
inspection, docs, experiments, or reasoning can settle it, do that work now instead.

```markdown
- `[OQ-2]` Should an event's tenant be derived from the session or carried on the envelope?
  — needs: `boundary` · event-envelope ownership, the tenancy model in `tenancy.spec.md`
```

`needs:` names one judgment class, then one to three knowledge prerequisites a person must
understand to judge it (what must be understood, not an explanation).

| Class       | The question is about                                   |
| ----------- | ------------------------------------------------------- |
| `boundary`  | An architectural boundary, ownership, or responsibility |
| `tradeoff`  | Competing desirable properties                          |
| `semantics` | What something means in the domain                      |
| `risk`      | Risk appetite, or an expensive or irreversible choice   |
| `priority`  | Product or business priority, scope cuts, milestones    |
| `compat`    | A compatibility or migration choice                     |

A question fitting no class is not an open question. Never raise one for identifiers, links,
placement, sequencing, derivable dependencies, formatting, naming, or anything the code answers.
On resolution, fold the answer into the item it changes, repoint live citations, and delete the
`[OQ-N]` line; record a rejected alternative in the absorbing item only when it has durable value.

## Identifiers

Sequential within a file, append-only, never renumbered, never reused; take the next free number
without asking. When an item's meaning changes, add a sub-version (`[VC-3]` → `[VC-3.1]`) and keep
the original struck through. Cross-spec references name both file and ID. Cross-reference with
repo-root-relative paths, never `./` or `../`. Code fences always specify a language.
