# Folder plans

The multi-file shape of the `writing-plan` skill, for a plan whose phase detail would make one file
hard to execute. `.plan/<slug>/` holds `index.md` plus one file per independently verifiable phase
(`01-tooling.md`, …).

`index.md` follows [PLAN-FORMAT.md](PLAN-FORMAT.md) and is the only status and checkbox authority — it alone owns
status, acceptance criteria, task checkboxes, final verification, open questions, and the log. Its
`## Implementation` collapses each task to one line pointing at the phase file with the detail:

```markdown
- [ ] **T-001** <task outcome> — [Details](01-phase.md#t-001--task-title)
```

Each phase file uses the readable task layout from [PLAN-FORMAT.md](PLAN-FORMAT.md), with task
headings beneath the phase heading. Omit each task's completion checkbox; status and checkboxes
belong only in the index:

````markdown
# Phase 1 — <independently verifiable outcome>

**Plan:** `index.md`
**Phase dependencies:** None | <earlier phase names>

## T-001 — <task title>

Requires: none or T-NNN · Covers: AC-001

<Short explanation of the intended outcome and where the change belongs.>

**Behavior**

- <required behavior or preservation constraint>

**Files**

- `path/to/file` — <responsibility>

**Verify**

```bash
<runnable verification command>
```

<Expected observable results.>
````

Rules on top of the single-file rules:

- Split only at independently verifiable phase boundaries.
- Task IDs are globally unique across phase files, and each block has exactly one matching `index.md`
  entry.
- Keep dependencies, acceptance links, and any `[P]` marker in the task detail block; the index
  lists outcomes and completion state. Match each index link to the actual task heading anchor.
- Phase files never duplicate the mutable state `index.md` owns.
