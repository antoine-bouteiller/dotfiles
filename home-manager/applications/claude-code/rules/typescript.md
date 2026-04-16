---
globs: ['*.ts', '*.tsx', '*.js', '*.jsx']
---

## Style

- 2-space indentation
- `const` only (`let` if reassignment required, never `var`)
- No `any` — use `unknown`
- Types only — no `interface`, no `enum`
- Named exports only — no default exports
- camelCase component names

## Naming

- Booleans prefixed: `is`, `has`, `should`, `can`

## CSS / Theming

- CSS classes only — no inline styles
- All colors/spacing/font-sizes via theme
- No arguments to style hooks — use CSS variables

## Type safety

- No `!!` or `Boolean()` casting
- No type casting — use type guards

## Component structure

- Simple: single `{Name}.tsx` file
- Complex: directory with `{Name}.tsx`, optional `.test.tsx`, `.styles.ts` (if >20 lines), `.types.ts`, `.hooks.ts`, `.utils.ts`, `.services.ts`
- Styles ≤20 lines stay in component file

## Commands

- `pnpm lint` / `pnpm prettier:check` / `pnpm build` / `pnpm test`
