---
description: Condense an implemented spec, preserving design intent and stripping implementation details
argument-hint: [path/to/spec.md]
allowed-tools: Read, Edit, Glob, Grep
---

# Condense Spec

**Spec path:** `$1`

If the spec path is empty, ASK THE USER before proceeding.

## Step 1 — Validate preconditions

1. Read the spec file at `$1`
2. Check `status:` in frontmatter — must be `implemented` or `amended` (with all VCs passing)
3. If status is `draft`, `review`, `accepted`, or `implementing`: **STOP** — the spec is not ready for condensation.
   Tell the user to run `/verify-spec` first.
4. If status is already `condensed`: **STOP** — already condensed.
5. Extract the **component inventory** from section 7
6. Extract the **`related:` frontmatter** to identify parent specs for potential reintegration

## Step 2 — Map implementation

For each component listed in section 7:

1. Find the implementing module (grep for key types from section 8 in `libs/java/`, `libs/typescript/`, `services/`)
2. Identify the **entry-point class or file** (the primary public API type)
3. Build a replacement table:

```markdown
| Component | Module | Entry point |
|-----------|--------|-------------|
| <name> | `<module-path>` | `<package.ClassName>` |
```

If a component cannot be found, flag it as `MISSING` and ask the user.

## Step 3 — Map test coverage

For each `[VC-N]` criterion in section 9:

1. Find the corresponding test class (grep for criterion ID or match by description)
2. Build an annotated list:

```markdown
- `[VC-1]` <criterion> — **PASS** (`<TestClassName>`)
- `[VC-2]` <criterion> — **PASS** (`<TestClassName>`)
```

If a test cannot be found, keep the criterion as-is without annotation.

## Step 4 — Condense

Apply edits to the spec file:

1. **Sections 2–6**: preserve verbatim — do not touch
2. **Section 7**: remove diagrams (Mermaid, ASCII art), keep only the component inventory table
3. **Section 8**: replace entire content with:

```markdown
### 8. Detailed Design

> Condensed after implementation. See source code for full detail.

| Component | Module | Entry point |
|-----------|--------|-------------|
| ... | ... | ... |
```

Use the table built in Step 2.

4. **Section 9**: replace with the annotated list from Step 3
5. **Section 10**: keep if any items remain unresolved, otherwise write "N/A"
6. **Changelog**: keep, and add a new entry:

```markdown
| <today> | Condensed | 7, 8, 9 | Post-implementation condensation — design intent preserved, implementation details removed |
```

7. **Frontmatter**: set `status: condensed`

## Step 5 — Reintegration (conditional)

Check if `related:` in the spec's frontmatter points to a **parent spec** (another `*.spec.md`, not a discovery doc or
ADR).

**If no parent spec**: skip this step. Report the condensation summary and stop.

**If parent spec exists**: ask the user:

> This spec references a parent spec at `<parent-path>`.
> Should I reintegrate this spec's design decisions into the parent?
> - Yes: merge sections 3 and 5 into the parent, add changelog entry
> - No: keep both specs as-is

**If user accepts reintegration:**

1. Read the parent spec
2. Merge rows from this spec's **section 3** (Key Design Decisions) into the parent's section 3 table
3. Merge items from this spec's **sections 5 and 6** (Non-Goals, Caveats) into the parent's sections 5 and 6
4. Add changelog entry to parent:

```markdown
| <today> | Reintegrated <child-spec-name> | 3, 5, 6 | Merged design decisions from <child-path> |
```

5. Add `reintegrated-into: <parent-path>` to this spec's frontmatter
6. Ask user: **Delete this spec file?** (only if fully reintegrated — all design decisions merged)

## Step 6 — Report

Present the condensation summary:

```
Spec condensed: <path>
- Status: condensed
- Sections preserved: 2, 3, 4, 5, 6
- Sections condensed: 7 (diagrams removed), 8 (replaced with pointer table), 9 (annotated with test refs)
- Reintegrated into: <parent-path> (if applicable)
- Lines before: N → Lines after: M (N% reduction)
```
