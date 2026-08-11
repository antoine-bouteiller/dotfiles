---
name: create-spec
description: Research a feature request and write a requirements spec to specs/<slug>.spec.md — problem, user stories, functional requirements, and measurable success criteria — without designing the implementation. Use when the user wants to "write a spec", "spec out" a feature, or agree on requirements and acceptance before any design or code. Precedes create-plan.
---

# Create a spec

Produce an agreed statement of **what** the feature must do and **why** it matters, then stop. You are
specifying, not designing: no tech stack, no file layout, no algorithms. `create-plan` turns an accepted spec
into a phased implementation plan; do not do its job here.

The file format — location, schema, rules, and quality gate — lives at
`~/.claude/skills/writing-spec/SKILL.md` (also `~/.agents/skills/writing-spec/SKILL.md`). Read it before
writing; this skill covers only the process.

## 1. Capture the request

Read the request and restate the feature in one paragraph: the problem, who has it, and why it matters now. If
the user gave a bare feature name with no problem behind it, ask what it solves before writing anything. Done
when you can name the actors, the triggering need, and the outcome that would make the feature worth shipping.

## 2. Ground it in the repo

Read the code and docs the feature touches — current behavior it changes, the users or callers it serves,
existing specs to stay consistent with, and any project instructions about specs. Cite existing behavior with
`path:line`. Stay read-only, and stay at the level of observable behavior rather than implementation. Done when
every requirement describes something real about the product rather than a guess about the codebase.

## 3. Resolve and confirm the path

Derive `<slug>` and resolve the location per the format skill, following the repo's existing spec convention
when it has one. **Always confirm the resolved path with the user before writing** — inference is a guess. If
the path already exists, stop and refuse to overwrite: report the existing file and let the user pick a new
slug or ask for an amendment. Done when the user has approved an unused path.

## 4. Draft the spec

Write the file to the schema in the format skill, with `status: draft`. Fill gaps with informed guesses drawn
from context and domain norms, and record every one under `## Assumptions` — an undocumented default is a
defect. Reserve `[NEEDS CLARIFICATION: <question>]` markers, within the cap the format skill sets, for choices
that have no reasonable default and would change scope, security, privacy, or user experience. Done when a
reader who has never seen the codebase can tell what shipping this feature means.

## 5. Clarify

Present each `[NEEDS CLARIFICATION]` marker as one numbered question with 2–4 concrete candidate answers and
the implication of each, using `AskUserQuestion` when available. Ask them together, wait for the answers, then
replace each marker with the chosen answer and move any resulting default into `## Assumptions`. Done when no
marker remains and no material unknown was silently resolved by you.

## 6. Validate against the quality gate

Apply the format skill's quality gate to the written file. Fix every failure and re-check, up to three passes;
if something still fails, record it under `## Open questions` and tell the user plainly rather than declaring
the spec ready. Once every check passes, set `status: review` and append the transition to `## Log`. Done when
the gate passes or the remaining gaps are explicit.

## 7. Hand off

Report the spec path, the goal, the user stories with priorities, the requirement and success-criteria counts,
and anything still open. Recommend `create-plan` as the next step, and say plainly that acceptance is the
user's call — you do not set `status: accepted` yourself. Do not implement, and do not commit unless asked.
Done when the user has a reviewable spec and knows what happens next.
