---
globs: ['*.spec.md']
---

## Implementing a spec

IMPORTANT: The spec is the single source of truth. Never implement beyond it, never guess when it is ambiguous — ask the user.

### Phase 0 — Discover (optional)

For new features or significant changes where the design space is unclear, run a structured discovery before writing the
spec. See `.claude/rules/discovery.md` for the workflow.

Discovery produces a `*.discovery.md` document that feeds directly into spec sections 2–7. Reference the discovery
document in the spec's `related:` frontmatter.

Skip Phase 0 when: the design is already clear, the spec is a bugfix variant, or the change is small enough that
exploration happens naturally during Phase 1 (Comprehend).

### Phase 1 — Comprehend

When given a spec file to implement, start writing code immediately. Do not spend time exploring the codebase or
planning unless explicitly asked. If context is needed, ask the user rather than autonomously exploring.

1. Read the entire spec file (for split specs, read `index.spec.md` + all component files in the `spec/` directory)
2. List every component from section 7
3. Map each to a Phoenix module type: Java lib → `libs/java/`, TS lib → `libs/typescript/`, Java service → `services/`, React app → `services/`
4. Identify dependencies between components (which must be built first)
5. Identify existing modules to modify vs new modules to scaffold
6. **STOP if section 10 (Open Questions) has unresolved items** — ask the user to resolve them before proceeding

### Phase 2 — Plan

1. Enter plan mode
2. Create an ordered task list respecting dependency order (foundations first, consumers last)
3. For each task specify: target module, files to create/modify, which verification criteria (`[VC-N]`) it satisfies
4. Identify archetypes for new modules:
   - Java lib → `/phoenix:create-java-lib`
   - Java service → `/phoenix:create-java-service`
   - TS lib → `/phoenix:create-typescript-lib`
   - React app → `/phoenix:create-react-app`
5. Flag any ambiguities discovered — ask user before exiting plan mode

### Phase 3 — Scaffold

1. Create new modules using the appropriate archetype skill
2. Add inter-module dependencies using `/phoenix:add-java-dependency`
3. Set up package structure: `<library>.<feature>/` (public API) + `<feature>.internal/` (implementation)
4. Add `package-info.java` with `@NullMarked` on every package, API warning on `internal` packages
5. Verify scaffold compiles: `./mvnw clean install -pl <module> -am`

### Phase 4 — Implement (per component)

Work in dependency order. For each component:

1. **Public API first** — interfaces, records, annotations, sealed types from section 8 "Data model" and "API surface"
2. **Internal implementation** — concrete classes in `.internal` package
3. **Dagger wiring** — `@Module` in public package, `@Provides` methods for internal bindings
4. **Configuration** — ConfigBean types with validation, `@TypeScriptStub` if spec requires TS stubs
5. **Tests alongside code** — write tests as you implement, not after. Follow verification criteria `[VC-N]`
6. **Build & verify** — `./mvnw clean install -pl <module> -am` after each component
7. **Commit** — one atomic commit per component using this format:

```
feat(<scope>): <description>

Implements <component> per <path/to/spec.md> section 8
Satisfies: [VC-1], [VC-2]
```

Use subagents for independent components that share no dependencies.

### Phase 5 — Integrate & Verify

1. Full build: `./mvnw clean install`
2. Start the server and check for runtime errors — build passing does not mean the code works. Check for runtime issues
   like recursive constructors, missing bindings, and enum hashing bugs.
3. Walk through **every** `[VC-N]` from section 9 — run the corresponding test or manual check. Do not skip items like
   creating test servers or running manual tests. Use the spec as a checklist.
4. Report a pass/fail table:

| Criterion | Status | Notes                            |
| --------- | ------ | -------------------------------- |
| VC-1      | PASS   |                                  |
| VC-2      | FAIL   | Missing edge case for null input |

5. Fix failures before declaring done

### Re-implementation after amendment

When a spec changes during or after implementation:

1. Diff the amendment against the previous version (use `git diff` on the spec file)
2. Identify affected components from section 7
3. Re-execute only phases 3–5 for affected components
4. Re-verify all `[VC-N]` criteria — original and new
5. Commit with message referencing the amendment: `feat(x): implement spec amendment — <reason>`

### Guardrails

- **Spec is law** — do not add features, refactor surrounding code, or "improve" beyond what the spec describes
- **Ask, don't guess** — if the spec is ambiguous or incomplete, ask the user
- **Build often** — compile after every component, not just at the end
- **Tests are mandatory** — every public API type must have at least one test
- **Atomic commits** — one component per commit, spec file path in commit message body
- **No forward references** — never depend on a component that hasn't been implemented yet
