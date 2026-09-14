# Spec format

Use this structure for a new spec when the repository has no established format. Omit empty optional
sections rather than filling a small spec with N/A. Keep meaningful existing sections when amending.

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

## 2. Problem Statement

<2–4 sentences: what problem this solves, why now, who is affected. Business context and
motivation, not implementation detail.>

- `[G-1]` <goal>
- `[G-2]` <goal>

## 3. Key Design Decisions

| Decision             | Choice         | Rationale                          |
| -------------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |

## 4. Principles & Intents

Guiding constraints that shape every subsequent detail; tiebreakers when the design is ambiguous.

- `[PI-1]` <principle — short name, then one clause of meaning>

## 5. Non-Goals

- `[NG-1]` <explicitly excluded capability>

## 6. Caveats

Known limitations, assumptions about external systems, constraints implementers must know.

- `[C-1]` <caveat>

## 7. High-Level Components

Optional diagram (Mermaid or ASCII), then the inventory:

| Component   | Module type | Responsibility | Public API surface         |
| ----------- | ----------- | -------------- | -------------------------- |
| Event Store | Java lib    | Persist events | `EventStore`, `EventQuery` |

An umbrella links each leaf and records its architectural dependencies:

| Leaf        | Depends on         | Rationale                  |
| ----------- | ------------------ | -------------------------- |
| transport   | —                  | Foundation                 |
| remote-sync | transport `[KD-2]` | Needs the framing contract |

## 8. Detailed Design

Give each component in §7 its own subsection. Specify its contracts using the relevant dimensions
under Contract detail below; for an umbrella, link to the leaves that own that detail.

## 9. Open Questions

- `[OQ-1]` <unresolved item needing a human decision> — owner: @name
```

IDs are sequential within their prefix. Preserve existing IDs and append new ones; annotate a
superseded decision instead of silently reusing its identifier. Cross-spec references name both
the file and ID because different specs may use the same local IDs. Paths in frontmatter are
repo-root-relative.

For umbrella trees, adapt section ownership using [UMBRELLA-SPECS.md](UMBRELLA-SPECS.md).
Execution task order belongs in a plan; a spec may describe component dependencies that constrain
the design.

## Contract detail

Include only dimensions that affect the design:

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

Use compact code or payload examples for the contract and its difficult branches. Include current
behavior where it explains compatibility; leave step-by-step implementation work to the plan.

## Amendments

Append a row under `## Changelog`:

| Date       | Amendment                     | Sections affected        | Reason         |
| ---------- | ----------------------------- | ------------------------ | -------------- |
| YYYY-MM-DD | Describe the changed contract | Relevant sections or IDs | Why it changed |

The amendment status and history must not imply that a previous acceptance covers the changed design.
