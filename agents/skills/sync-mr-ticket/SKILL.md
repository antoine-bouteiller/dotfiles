---
name: sync-mr-ticket
description: Update a GitLab merge request title and description; also update its linked Linear implementation summary when requested.
disable-model-invocation: true
---

# Sync MR and ticket

Choose the requested scope first. "Update the MR" updates only the MR. "Update the MR and ticket"
updates both. Invoking this skill to sync both authorizes both descriptions, not ticket status,
assignee, labels, or unrelated fields. Finishing a feature alone does not authorize external writes.
Honor narrower field requests: "update the description" preserves the title, and a title-only
request preserves the description. Include only the requested fields in update payloads.

## Resolve and read

Use an explicit MR supplied by the user; otherwise resolve the current branch against the correct
GitLab host and project:

```bash
git branch --show-current
glab mr list --source-branch "<branch>"
```

Match the source branch and project exactly. With zero or multiple matches, investigate repository
and request context; ask if the target remains ambiguous. Do not reuse an unverified IID from memory.

Fetch the MR's existing title, description, actual target/head, diff, and relevant requirements.
Draft from the implemented change and verified checks, not just commit subjects or planned work.
Honor repository templates and preserve manually maintained context.

For a requested ticket update, prefer an explicit ticket or a verified MR link. A branch prefix such
as `phx-118-add-filter` can suggest `PHX-118`; fetch it and confirm it matches the work. Ask only
when a ticket update is requested and the ticket cannot be resolved reliably.

## Prepare the text

Lead with the problem and resulting behavior. Add design details and validation only where useful
for review. Match the repository's title convention. Use a short paragraph for simple changes and
bullets when they make distinct changes easier to scan.

For Linear, preserve requirements, acceptance criteria, discussion context, and unrelated text.
Replace an existing implementation summary or append a clearly labeled one; do not replace the
whole ticket with the MR body. Distinguish shipped behavior from incomplete ticket requirements.
Keep useful existing links; add links when the integration does not already expose the relationship.
Do not add AI attribution.

## Apply and verify

Prepare the exact proposed text before requesting any permission that is still required. Reuse
existing authorization rather than asking again. Check that the descriptions have not changed
since reading them; reconcile concurrent edits before writing.

Use structured tool arguments or a JSON payload file for multiline updates. With `glab api`, send
a PUT to `projects/<project-id>/merge_requests/<iid>` using `--input <payload-file>` with the
authorized `title` and/or `description` fields. Resolve placeholders and serialize JSON without
shell interpolation.

Discover an available authenticated Linear issue-update tool for ticket writes. A read-only
connector does not provide write access. If writing is unavailable, report the specific missing
capability and provide the prepared ticket text; complete an independently authorized MR update.

Read back each changed record to verify the intended fields and preservation of existing context.
After an uncertain response, read current state before retrying. Report which updates succeeded,
with links, and any remaining failure; do not imply the two services update atomically.
