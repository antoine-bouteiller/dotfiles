# Spec trees

Promote a spec to a tree when it has three or more components with non-trivial design, a
component's Contracts exceed ~200 lines, components will be implemented in parallel, or different
people own different parts. Do not split under ~300 lines, for a single component, or when parts
are too coupled to separate.

```text
<module>/spec/
├── <area>.spec.md          # kind: umbrella
├── <component-a>.spec.md   # leaf
└── <sub-area>/
    ├── <sub-area>.spec.md  # kind: umbrella
    └── <leaf-b>.spec.md
```

Every directory holding specs has exactly one `kind: umbrella` spec. A leaf's parent is the
umbrella in its directory; a sub-umbrella's parent is the umbrella in the parent directory. The
filesystem is the only source of truth, so there is no `parent-spec:` field. Each level carries
its own `status:`; aggregate readiness comes from walking the tree, never from the root's status.

## Boundaries

In priority order:

1. **Minimize cross-leaf seams.** A seam is any contract two leaves share; each unpinned seam is a
   future interrupt.
2. **One leaf, one write path.** Disjoint `module:` sets let leaves run in parallel.
3. **At most six leaves per umbrella.** Past six, group under a sub-umbrella; depth is cheaper than
   breadth.
4. **A leaf is one worker's unit.** Several unrelated modules or more than ~25 criteria means split;
   one file with no distinct verification surface means fold into a neighbor.

## Ownership

| Level    | Owns                                                                                                       | Must not carry                              |
| -------- | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| Umbrella | `[G]`, `[NG]`, tree-wide `[PI]`, the derived inventory, cross-cutting `[VC]`, tree-wide `[SO]`             | Leaf-grade contract detail                  |
| Leaf     | Its Contracts, its own `[KD]`/`[C]`/`[VC]`/`[SO]`, leaf-scoped `[PI]` citing the umbrella item they refine | `[G]`; non-goals that move the tree's scope |

Upward cascade is mandatory: when a leaf supersedes an umbrella item, annotate the umbrella item in
the same change (`superseded by <leaf path> [KD-N]`). Keep each cross-leaf contract in one leaf and
cite it from consumers.

## Execution order

Order is derived, not authored:

- **Logical** — leaf B's contracts cite leaf A's, so B follows A.
- **Serialization** — two leaves writing the same module cannot run together.
- **Priority** — the only human-authored ordering, recording a decision (ship this first) rather
  than a constraint.

An umbrella's `## Design` may end with an execution-order table of vertical stages, each with a
"Green when" condition, when stages cross leaves; write it only against shipped code, never as a
guess from the derived graph.
