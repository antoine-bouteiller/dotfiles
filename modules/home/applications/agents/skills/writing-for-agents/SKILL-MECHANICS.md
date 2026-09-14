# Skill mechanics

Keep required `name` and `description` frontmatter concise and useful for discovery. Match the
directory name to the skill name and preserve supported optional metadata. Put workflow instructions
in the body; descriptions carry the capability and selection criteria, not the procedure.

On Codex, consult the installed native `skill-creator` when initialization, packaging tools, or
metadata editing is needed. Use its current schemas and helpers rather than copying them here.
The writing principles in this skill also apply to hosts without that native skill.

## Supporting resources

Use references for substantial conditional guidance, with a link explaining when to read each one.
Use scripts when they avoid repeatedly recreating logic or materially improve execution reliability;
run new or changed scripts to verify them. Use assets for files copied or adapted into the output,
not as instructions to load by default. Create each resource only when its concrete benefit justifies it.

## Invocation across hosts

Automatic discovery is the default. Preserve an existing invocation policy; choose explicit-only
for a new skill only when the user requests it. Sensitive operations alone do not justify disabling
discovery: require authorization at the action boundary. Preserve unrelated UI, policy, and
dependency fields when changing metadata; a generator that replaces a file may discard them.

This repository shares skill folders across agent hosts:

- **Codex:** `agents/openai.yaml` controls implicit invocation with
  `policy.allow_implicit_invocation: false`.
- **Claude Code:** `disable-model-invocation: true` in `SKILL.md` controls automatic invocation.
  Keep that field for existing explicit-only skills alongside the Codex policy.
- **Other hosts:** check their supported metadata rather than assuming either setting applies.

Refer to other skills by their registered names, for example, "Use the `writing-tests` skill."
Use relative links for supporting documents such as `PLAN-FORMAT.md` or `mocking.md`, rather than
for another skill's entrypoint. A named reference does not change invocation policy or grant
additional execution permissions. Keep shared references inside their owning skill and link to them.

Host-specific tool names, model aliases, and authentication steps belong only in guidance for that
host. Prefer capability descriptions and available-tool discovery in shared workflows.

## Validation

Validate common frontmatter and links, then check host-specific fields separately. The bundled
Codex `quick_validate.py` rejects Claude's `disable-model-invocation` key even when a shared skill
deliberately preserves it. Report that compatibility distinction; do not remove a working host
policy merely to silence a different host's validator. A normalized temporary copy can validate the
common fields without changing the source.

Add UI metadata, scripts, or routers only when the workflow needs them. A router is useful for
selecting among distinct tasks, not for bypassing invocation policy or user authorization.
