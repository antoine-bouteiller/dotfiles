---
globs: ['*.spec.md']
---

## Spec document structure

Every `*.spec.md` MUST follow this hierarchy. Include every section heading — use "N/A" if not applicable.

### 1. Frontmatter

```markdown
---
title: <component/service/library name>
status: draft | review | accepted | implementing | implemented | amended | condensed
author: <name>
date: <YYYY-MM-DD>
related: [path/to/other.spec.md, doc/architecture/sse/adr.md]
---
```

### Spec file location

- **Single-module spec** → colocate in the module directory: `src/modules/event-store/event-store.spec.md` (or `src/features/…`, `src/lib/…` — match the project's layout)
- **Cross-cutting spec** → place in `docs/specs/`: `docs/specs/latency-tiers.spec.md`
- **Bugfix spec** → colocate next to the original spec it references

### Splitting a spec

A single `*.spec.md` file is the default. Promote to a directory when:

- Spec has **3+ components** with non-trivial detailed design sections
- Any component's section 8 exceeds ~200 lines
- Components will be implemented by **parallel subagents**
- Different teams own different components

**Do NOT split** if the spec is under ~300 lines, covers a single component, or components are too coupled to separate.

When splitting, promote the file to a `spec/` directory:

```
src/modules/event-store/spec/
├── index.spec.md          # Sections 1–7, 9–10 (overview, decisions, component inventory)
├── store-api.spec.md      # Section 8 deep dive for Store API component
├── query-engine.spec.md   # Section 8 deep dive for Query Engine component
└── changelog.spec.md      # Shared changelog (optional, can stay in index)
```

- **Index file**: `index.spec.md` — everything except per-component detailed design
- **Component files**: `{component-name}.spec.md` — kebab-case matching the component inventory table
- Each component file's frontmatter uses `related:` to point back to `index.spec.md`
- During implementation, subagents receive only the index + their component file

### 2. Problem Statement

What problem does this solve, why now, who is affected. Business context and motivation — not implementation details. List concrete goals with `[G-N]` prefixes:

- `[G-1]` First goal
- `[G-2]` Second goal

### 3. Key Design Decisions

Top-level architectural choices with rationale. Link to ADRs (`doc/architecture/*/adr.md`) when they exist. Number each decision with `[KD-N]`:

| Decision          | Choice         | Rationale                          |
| ----------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |

### 4. Principles & Intents

Guiding constraints that shape every subsequent detail (e.g., "compute-on-write", "immutable models", "no runtime reflection"). These act as tiebreakers when the detailed design is ambiguous. Number each principle with `[PI-N]`:

- `[PI-1]` Compute-on-write — pre-compute at ingestion, not at query time
- `[PI-2]` Immutable models — all domain types are `readonly` interfaces or discriminated unions; no mutation after construction
- `[PI-3]` Strict typing — no `any`, no unchecked casts; prefer discriminated unions and `satisfies` over type assertions

### 5. Non-Goals

What this spec explicitly does NOT aim to achieve. Non-goals prevent scope creep during implementation. Number each with `[NG-N]`:

- `[NG-1]` First non-goal
- `[NG-2]` Second non-goal

### 6. Caveats

Known limitations, assumptions about external systems, and constraints that implementers must be aware of. Number each with `[C-N]`:

- `[C-1]` First caveat
- `[C-2]` Second caveat

### 7. High-Level Components

- Overview diagram (Mermaid or ASCII)
- Component inventory table:

| Component   | Module type        | Responsibility | Public API surface (exports)       |
| ----------- | ------------------ | -------------- | ---------------------------------- |
| Event Store | Server module      | Persist events | `EventStore`, `EventQuery`, types  |
| Dashboard   | React feature      | Render events  | `<EventTimeline />`, `useEvents()` |
| Ingest API  | HTTP route handler | HTTP endpoints | `POST /events`, `GET /events/:id`  |

**Module type** examples: `server module`, `React feature`, `React component`, `hook`, `HTTP route handler`, `tRPC router`, `Zod schema`, `CLI command`, `worker`, `utility`.

**Public API surface** should enumerate the exports from the module's `index.ts` barrel — the contract the rest of the app consumes. For route handlers, list the HTTP routes instead.

### 8. Detailed Design

Per-component deep dive. For each component listed in section 7:

- **Data model / types** — interfaces, type aliases, discriminated unions, enums, Zod schemas with code examples. Prefer `readonly` fields; mark optional with `?`; use `satisfies` instead of type assertions where possible.
- **API surface** — exported functions, classes, hooks, components; their signatures and JSDoc-worthy invariants. For HTTP routes, document method + path + request/response schema.
- **Interactions** — how this component calls or is called by others (sequence diagrams encouraged). Note async boundaries (`Promise`, streams, event emitters).
- **Configuration** — env vars, JSON/YAML shape, Zod validation schema, defaults. Reference the `.env.example` keys.
- **Error handling** — failure modes, recovery strategies, error types (custom `Error` subclasses or discriminated `Result` unions). Distinguish expected errors (return) from unexpected (throw).
- **Examples** — end-to-end usage showing how pieces compose, including import paths.

Code examples MUST specify language — default to `typescript`, use `tsx` for JSX, `bash` for shell, `json` for config. Use Aspect/Detail tables for summaries.

### 9. Verification Criteria

Concrete, testable acceptance criteria. Each criterion should map to at least one test:

- `[VC-1]` Given X, when Y, then Z
- `[VC-2]` Type-check passes: `pnpm tsc --noEmit` (or `npm run typecheck`)
- `[VC-3]` Unit tests pass: `pnpm test src/modules/<name>` (Vitest/Jest)
- `[VC-4]` Lint passes with no new warnings: `pnpm lint`
- `[VC-5]` Integration test covers cross-component interaction
- `[VC-6]` No new `any`, `as` casts, or `@ts-ignore` introduced

### 10. Open Questions

Unresolved items requiring human decision before implementation. Tag with owner and deadline if known. Number each with `[OQ-N]`:

- `[OQ-1]` First open question — owner: @name, deadline: YYYY-MM-DD
- `[OQ-2]` Second open question

---

## Formatting conventions

- Use Aspect/Detail tables for metadata and component summaries
- Cross-reference related docs with relative paths from repo root
- `> **Note:**` blockquotes for important callouts
- ASCII tree diagrams for directory/module hierarchies
- Mermaid diagrams for component interactions and sequences
- Inline types as fenced `typescript` blocks rather than prose descriptions — the type *is* the spec

## Numbered item conventions

Use `[PREFIX-N]` prefixes for items that need cross-referencing between specs, tests, and discussions. Sequential numbering within each section, starting at 1.

| Prefix | Section | Example |
| ------ | ------- | ------- |
| `[G-N]` | 2. Problem Statement (goals) | `[G-1]` Support 1Bn events |
| `[KD-N]` | 3. Key Design Decisions | `[KD-1]` Persistence |
| `[PI-N]` | 4. Principles & Intents | `[PI-1]` Compute-on-write |
| `[NG-N]` | 5. Non-Goals | `[NG-1]` Multi-region replication |
| `[C-N]` | 6. Caveats | `[C-1]` Assumes Postgres 16+ |
| `[VC-N]` | 9. Verification Criteria | `[VC-1]` Given X, when Y, then Z |
| `[OQ-N]` | 10. Open Questions | `[OQ-1]` Which auth provider? |

When amending, use sub-versions (`[VC-N.1]`, `[G-N.1]`) to distinguish new items from originals.

## Iterative development

### Spec lifecycle

Track status in frontmatter: `draft` → `review` → `accepted` → `implementing` → `implemented` → `condensed`.
Use `amended` when revising a previously accepted or implemented spec.

### Amending a spec

Specs are living documents. Amend in-place — do not create separate amendment files.

1. Update the affected sections (design, components, verification criteria)
2. Set `status: amended`
3. Add an entry to the `## Changelog` section at the bottom of the spec:

```markdown
## Changelog

| Date       | Amendment         | Sections affected | Reason                                     |
| ---------- | ----------------- | ----------------- | ------------------------------------------ |
| 2026-03-15 | Add caching layer | 7, 8.3, 9         | Performance requirements from load testing |
```

4. Prefix new or modified numbered items with sub-versions (e.g., `[VC-N.1]`, `[G-N.1]`) to distinguish from originals

### When to create a new spec

- New feature or independent component not covered by any existing spec
- Bugfix for previously implemented spec (use bugfix variant below)
- Scope diverges enough that the original problem statement no longer applies

### Bugfix spec variant

For fixing bugs in spec-implemented code, use a lightweight `*.spec.md` with:

1. Frontmatter with `related:` pointing to the original spec
2. **Current Behavior** — what is broken, with reproduction steps
3. **Expected Behavior** — correct behavior per original spec
4. **Unchanged Behavior** — what must NOT change (regression guard)
5. **Fix Design** — targeted changes only
6. **Verification Criteria** — tests proving the fix and non-regression

### Condensing a spec

After implementation and verification, condense the spec to preserve design intent while stripping implementation
details that now live in the code. Run `/condense-spec <path>`.

**Preserve verbatim** (design intent — not recoverable from code):
- Section 2 (Problem Statement), 3 (Key Design Decisions), 4 (Principles & Intents), 5 (Non-Goals), 6 (Caveats)
- Section 10 (Open Questions) if any remain unresolved
- Changelog

**Condense** (implementation details — now live in code):
- Section 7: keep inventory table only, remove diagrams
- Section 8: replace with a pointer table mapping components to module paths and entry-point files (e.g. `src/modules/event-store/index.ts`)
- Section 9: keep criteria list, annotate with test file references (e.g. `src/modules/event-store/event-store.test.ts`)

**Reintegration:** When a spec's `related:` points to a parent spec (bugfix or amendment), the condensation step offers
to merge the child's design decisions (sections 3, 5, 6) back into the parent spec and mark the child as
`reintegrated-into: <parent-path>` in frontmatter.
