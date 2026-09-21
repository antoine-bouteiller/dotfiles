# Umbrella specs

Use a tree for substantial, independently understandable component designs. Keep shared contracts
and decisions in one umbrella and detailed component design in leaves. Split by design ownership,
not by an arbitrary file count or the number of available agents.

```text
<module-dir>/spec/
├── <area>.spec.md          # kind: umbrella
├── <component-a>.spec.md   # parent-spec: repo-root-relative umbrella path
└── <sub-area>/
    ├── <sub-area>.spec.md  # kind: umbrella; parent-spec: parent umbrella path
    └── <leaf-b>.spec.md    # parent-spec: sub-area umbrella path
```

Use one umbrella per directory. Add a sub-umbrella only when it groups cohesive designs and reduces
navigation burden. A leaf may span modules when they form one coherent contract.

## Ownership and links

The umbrella owns shared goals, principles, non-goals, constraints, cross-component decisions,
tree-wide outcomes and acceptance, and the component inventory. Its Contracts section links to the
leaf owners rather than copying their detail. A leaf owns its component contracts, decisions,
outcomes, and acceptance criteria, and may refine shared requirements with explicit file-and-ID
references. A leaf cannot silently redefine the tree's scope.

Each leaf's `parent-spec` points to its directory's umbrella using a repo-root-relative path.
A sub-umbrella points to the parent umbrella. `related` holds informational links rather than
structural ownership. The umbrella inventory links to every direct child; each child has one parent.

Derive the inventory from the actual child specs and their ownership. Record architectural
dependencies by citing the contracts consumers need, not by guessing an implementation order.
Implementation sequence, write-path serialization, and task status live in the plan. Keep
cross-component APIs in a single authoritative location and link from consumers.

## Amend and check

When a leaf changes a shared contract, amend the umbrella and affected leaves together. Record
supersession and durable rationale beside the affected items, preserving IDs. Refresh affected
leaf and tree-wide outcomes and acceptance criteria. Check both directions of parent/inventory
links, ownership of shared sections, and compatibility between connected contracts.
