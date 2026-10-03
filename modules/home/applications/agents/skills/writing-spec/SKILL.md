---
name: writing-spec
description: Write or amend a design specification with intent, shipped outcomes, contracts, and acceptance criteria for a feature or architectural change.
---

# Write a design spec

A spec records the current design truth: why the system exists, how the design tends to achieve
it, what becomes true when it ships, the contracts that shape it, and how correctness is shown.
It is the single source of truth an implementation follows; task breakdowns and execution order
are derived from it at implementation time, not authored here.

If the repository provides its own spec workflow, such as `.claude/rules/spec.md`, `/spec:*`
commands, or `*.feature.json` companions, follow it; where it conflicts with this skill, the
repository workflow wins.

## Ground the design

Read the request, affected code, existing specs, docs, and constraints before writing. When the
user states a contract in prose, put their words into the spec first and justify every addition
against them. An addition that changes the count of surfaces, types, layers, or paths the user
named is a spec change, not an elaboration: ask before building on it.

Ask about concept set, shape, and count before writing the body; names are cheap to change, a
concept set is what the document is built on. Resolve factual unknowns through code, docs, or
bounded experiments within the task's authorization. Ask only when human judgment is needed.

## Choose the document

Use the user's path or the repository's convention, including its extension (`.spec.md` or
`.spec.mdx`). Otherwise:

- Single-module spec: `<module-dir>/<slug>.spec.md`.
- Cross-cutting spec: `doc/architecture/specs/<slug>.spec.md`.
- Bugfix spec: next to the spec it fixes, naming it in `related:` and in `## Why`.

If the path exists, amend it when it is the requested spec; otherwise choose a distinct path.
A single file is the default. Read [TREES.md](TREES.md) when a design may need an umbrella tree
or when changing an existing one.

## Draft or amend

Read [SPEC-FORMAT.md](SPEC-FORMAT.md) for the frontmatter, the seven sections, identifiers, and
contract shape.

- **Show the contract; do not describe it.** Write the signature, schema, event shape, or config
  block, then prose only for what it cannot carry: why it exists, what it guarantees, what it
  forbids. Delete a paragraph the fenced block above it already says. Consult the
  `choosing-visuals` skill when a diagram carries the design better.
- **Density tracks implementation maturity.** A `draft` with no code behind it is thin: goals,
  shape-constraining decisions, non-goals, and blocking questions. Rationale earns length by citing
  a measurement, a shipped constraint, or another spec.
- **Record what was decided, not how it was reached.** No rewrite counts, drafted-and-deleted
  alternatives, or reasoning narratives. Keep a rationale inside its item only when the choice is
  surprising, externally constrained, expensive to reverse, likely to be reconsidered, or prevents
  a known-invalid alternative from returning. Git is the amendment history; there is no changelog.
- **Derive Outcome** from resolved decisions, contracts, and criteria; never invent scope while
  summarizing.

Amend in place, never in a separate amendment file. Set `status: amended`, sub-version items whose
meaning changed, refresh Outcome and affected Acceptance, and reconcile dependent contracts and
tree levels in the same change. When the spec disagrees with shipped, tested code, amend the spec
to match the code.

If the spec carries inline `REVIEW: <comment>` markers, apply instructions, answer fact-based
questions, and remove resolved markers; reply to anything ambiguous with a `REPLY:` marker.

## Decision rights

Decide and report: the requested change and its mechanical follow-through; format fixes; new
`[KD]`/`[PI]`/`[C]`/`[VC]`/`[CT]` items recording a decision legitimately made under the task,
such as naming or module placement; reconciling the spec with shipped code; Outcome; status
transitions; numbering and restructuring that renumbers nothing.

The user decides before it lands: new or altered `[G]`/`[NG]`; anything changing product scope,
costing money, or mutating a real environment; changes to shipped behavior, a public API, or a
schema in use; prose carrying new design intent rather than recording a decision. Never insert
such an extrapolation silently; ask, or leave a `REPLY:` marker.

## Review readiness

Run three passes, in order; each asks a different question:

1. **Slim** — does deleting this item change what gets built? Remove what does not.
2. **Harden** — would an agent implementing this have to stop and ask? Close it by reading code
   and docs: verify cited states, paths, extensions, counts, and contracts against what exists.
3. **Check** — is it well-formed and self-consistent? Every changed item agrees with every other;
   resolve contradictions through the precedence ladder in the `implement` skill and escalate only
   genuine arbitrations. Outcome is present, current, and every `[SO]` is demonstrated by a `[VC]`.
   IDs are unique and cited IDs exist; paths are repo-root-relative and resolve; tree structure
   holds.

Closing every Open Question is not readiness: if an informed reader cannot say what will ship, the
spec is not ready. Link and format checks prove well-formedness, never rightness; report them in
one clause, not as the verdict.

A new spec that passes becomes `review`; an amendment stays `amended`. Only the user sets
`accepted`. Report the path, key decisions, and remaining questions. Stop before implementation
unless it is authorized; then continue with the `implement` skill. Commit only when authorized.

## After implementation

The `implement` skill moves status through `implementing` to `implemented` and fills contract
anchors. When asked to condense, reconcile the spec with the code it now describes: resolve every
anchor, classify divergences, keep Why, Design, Outcome, contract intent with anchors, invariants,
Caveats, and Acceptance meaning, remove detail the anchored code makes authoritative, and set
`status: condensed`.
