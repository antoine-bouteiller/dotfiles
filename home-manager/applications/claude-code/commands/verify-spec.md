---
description: Verify implementation against spec, find gaps, update statuses
argument-hint: [path/to/spec.md]
allowed-tools: Read, Edit, Glob, Grep, Bash(./mvnw:*), Bash(git diff:*), Bash(git log:*)
---

# Verify Spec Implementation

**Spec path:** `$1`

If the spec path is empty, ASK THE USER before proceeding.

## Step 1 — Read the spec

1. Read the spec file at `$1`
2. **If `$1` is a `spec/` directory or `index.spec.md`**: also read all sibling `*.spec.md` component files in the same
   directory. If `$1` is a single spec file in a non-`spec/` directory, proceed normally.
3. Extract **all `[VC-N]` criteria** from section 9 (Verification Criteria)
4. Extract the **component inventory** from section 7 (module paths, module types)
5. Extract the **`related:` frontmatter** to find linked discovery docs
6. Note the current `status:` value

## Step 2 — Build

Run the build for all modules listed in section 7:

```
./mvnw clean install -pl <module1>,<module2> -am
```

If the build fails, report the error and stop. Fix the build before proceeding.

## Step 3 — Verify each criterion

For each `[VC-N]` criterion extracted in Step 1:

1. **Find the corresponding test(s):** Grep for the criterion ID (`VC-N`) in test files, or match the criterion
   description to test method names
2. **If the criterion references a build command** (e.g., "builds with `./mvnw clean install`"): confirm the build from
   Step 2 passed
3. **If the criterion references an API surface** (e.g., "type `Foo` exists with method `bar`"): grep for the type and
   verify it matches the spec's section 8 description
4. **If the criterion references behavior** (e.g., "given X, when Y, then Z"): find and run the corresponding test
5. Record the result: **PASS**, **FAIL** (with reason), or **MISSING** (no test found)

## Step 4 — Report gap table

Present the results to the user:

```markdown
| Criterion | Status  | Notes                                  |
| --------- | ------- | -------------------------------------- |
| VC-1      | PASS    |                                        |
| VC-2      | FAIL    | Null handling missing in FooService    |
| VC-3      | MISSING | No test found for cross-module query   |
```

If **all criteria pass**, skip to Step 6a.

## Step 5 — Triage gaps

For each FAIL or MISSING criterion, ask the user:

> **[VC-N] — <criterion description>**
> Status: FAIL/MISSING — <reason>
>
> Is this tractable (fix now) or non-tractable (defer)?

**Tractable** → fix the implementation, then re-run from Step 2.

**Non-tractable** → collect for escalation in Step 6b.

## Step 6 — Update statuses

### 6a — All criteria pass

1. **Update spec frontmatter:** set `status: implemented`
2. **Add changelog entry** to the spec:

```markdown
## Changelog

| Date       | Amendment                 | Sections affected | Reason                          |
| ---------- | ------------------------- | ----------------- | ------------------------------- |
| <today>    | Verification complete     | 1 (status)        | All [VC-N] criteria passing     |
```

3. **Update linked discovery doc** (if `related:` points to a `*.discovery.md`): set `status: graduated`
4. Report final summary:

```
Verification complete. All [VC-N] criteria pass.
- Spec status: implemented
- Discovery status: graduated (if applicable)
```

### 6b — Some criteria deferred

1. **Add non-tractable gaps to spec section 10** (Open Questions):

```markdown
### Open Questions

N. **[VC-X] <criterion>** — <reason it cannot be resolved now>. Requires: <followup action>.
```

2. **Update spec frontmatter:** set `status: amended`
3. **Add changelog entry:**

```markdown
## Changelog

| Date       | Amendment                   | Sections affected | Reason                                       |
| ---------- | --------------------------- | ----------------- | -------------------------------------------- |
| <today>    | Partial verification        | 1, 9              | VC-X deferred: <reason>                      |
```

4. **If gaps require further exploration**, suggest creating a new discovery doc:

```
Suggest: create <module>/verification.discovery.md with related: [$1]
Goal: resolve deferred gaps [VC-X, VC-Y]
```

5. Report final summary:

```
Verification partial. N/M criteria pass, K deferred.
- Spec status: amended
- Deferred: [VC-X] <reason>, [VC-Y] <reason>
- Suggested followup: <discovery or spec amendment>
```
