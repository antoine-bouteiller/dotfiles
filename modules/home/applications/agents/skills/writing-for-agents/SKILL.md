---
name: writing-for-agents
description: Write or revise instructions consumed by agents, including skills, AGENTS.md, CLAUDE.md, and linked workflow references.
---

# Write for agents

Assume the agent is already capable. Write only guidance that changes its decisions or improves
its work: non-obvious constraints, local conventions, operational invariants, and useful evidence
of completion. Omit generic tutorials, repeated instructions, and speculative edge cases.

When the document is a skill, read [SKILL-MECHANICS.md](SKILL-MECHANICS.md) for packaging and invocation.

## Preserve intent and scope

Support the user's requested task and chosen product. Instructions must not expand the assignment,
modify unrelated configuration, or imply permission for additional external actions. Reuse prior
decisions and authorization; ask only when missing information materially changes the work and
cannot reasonably be inferred.

Distinguish requirements from recommendations and local conventions. A particular example, past
failure, or preference is not automatically a universal rule. Correct the demonstrated problem
at its actual boundary rather than restricting unrelated work.

## Match specificity to risk

For open-ended work, describe the outcome and decision criteria. For a preferred workflow, provide
a useful example or adaptable procedure. Reserve fixed sequences, narrow parameters, and absolute
language for cases where deviation causes a concrete correctness, safety, or permission problem.

Preserve operational invariants without prescribing incidental implementation choices. Use
checkable completion criteria proportional to the task. Retrying workflows and external writes
need a stopping condition proportional to their risk; successful task authorization does not
remove that boundary. Avoid restating policies already enforced by the host.

Prefer concrete positive instructions and use direct prohibitions for real boundaries. Compact
terms can help when their meaning is shared, but should not replace precise requirements.

## Make discovery precise

A description or document link is a **context pointer**. State what the target helps with and when
to read it. Distinguish genuinely different uses; avoid lists of synonyms and broad triggers that
pull specialized workflows into unrelated work.

Describe the capability and when it applies; add exclusions only to prevent likely misrouting.
Refer to another skill or tool only when the workflow needs it and it is available in the target
environment. Specialized reviews or audits should apply when requested or genuinely needed,
rather than merely because ordinary work touches the subject.

## Disclose detail progressively

Keep purpose, essential constraints, shared workflow, and routing in the entrypoint. Put substantial
mode-specific procedures, schemas, templates, and examples behind links that explain when to read
them. Load only the references relevant to the current task. A simple document needs no router or
extra files; a length limit is not a target.

Group a rule with its rationale and exceptions. Keep each maintained fact in one authoritative
place. Look up facts that already live in configuration or tool help instead of copying them into
instructions, unless discovery is expensive or the reason behind the configuration is otherwise lost.

Split at meaningful task or mode boundaries. Before removing a reference, inspect its callers and
purpose. Avoid copied manuals and auxiliary documentation that the workflow does not use.

## Prune and validate

Check whether each instruction changes a decision, preserves an invariant, or clarifies the task.
Remove stale environment assumptions and examples that add no useful distinction. Prefer a narrow
correction supported by real usage over accumulating rules for every imaginable failure.

Check links, metadata, and consistency with connected workflows. Structural validation does not
establish good decisions. When behavioral validation adds meaningful confidence, exercise realistic
requests and inspect observable outcomes, not exact wording or headings.

For complex or risky changes, use an independent evaluation when delegation is available and
authorized. Supply the request, instructions, and minimum raw artifacts without revealing the
intended answer or suspected defect. Bound side effects and keep generated artifacts in an isolated
temporary workspace. Small edits do not automatically require delegation. Treat prompting heuristics
as hypotheses to evaluate, and revise only where the observed behavior supports a change.
