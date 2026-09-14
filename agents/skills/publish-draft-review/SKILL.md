---
name: publish-draft-review
description: Attach review findings to a GitLab merge request as unpublished inline draft notes when the user requests draft comments.
disable-model-invocation: true
---

# Create draft review notes

Create only the requested draft notes. A review request alone does not authorize posting them.
Drafts remain unpublished; publishing a review is a separate action requiring explicit authorization.

## Resolve the diff

Resolve the requested MR, or discover it from the current branch and repository. Read the findings,
current MR diff, and `diff_refs` from `GET projects/<project-id>/merge_requests/<iid>`.
Use the server's `base_sha`, `start_sha`, and `head_sha`, not guessed local revisions.
Read all relevant diff pages and detect truncated or unavailable hunks before choosing anchors.

Read existing draft notes, including pagination, so reruns do not duplicate findings. Identify a
matching draft by its finding, body, and diff position; do not alter unrelated notes.

## Build inline positions

Use the diff entry's actual `old_path` and `new_path`, including renames. Supply both paths and
the three diff SHAs for every text position, with `position_type: "text"`.

| Line in the diff                     | Line fields                    |
| ------------------------------------ | ------------------------------ |
| Added line                           | `new_line`                     |
| Deleted line                         | `old_line`                     |
| Unchanged context line inside a hunk | Both `old_line` and `new_line` |

Walk hunk headers to compute positions: context advances both counters, a deletion only the old
counter, an addition only the new counter. The "\ No newline at end of file" marker advances neither.
Only anchor to a line present in the reviewed hunk. When the real location is outside the diff,
use a relevant visible line and name the real location in the comment; if no honest inline anchor
exists, report the finding as unanchored instead of attaching it arbitrarily.

Write a JSON payload file for each note using the available file-writing tool:

```json
{
  "note": "The finding and its concrete consequence.",
  "position": {
    "base_sha": "<base>",
    "start_sha": "<start>",
    "head_sha": "<head>",
    "position_type": "text",
    "old_path": "src/old-name.ts",
    "new_path": "src/new-name.ts",
    "new_line": 42
  }
}
```

Nested `position` data must survive serialization. A JSON file avoids flattened form fields and
stdin/pipeline issues; use `--input <file>` with `glab api`. Discover installed binaries normally.
If a command or stdin path fails, inspect the local installation instead of assuming a fixed PATH.

## Post and reconcile

Recheck diff refs before each write. If they changed, fetch the current diff and reassess the
finding and anchor; do not post using the stale position. Repeatedly changing refs are a reason
to pause and report the unstable target.

```bash
glab api --method POST "projects/<project-id>/merge_requests/<iid>/draft_notes" \
  --header "Content-Type: application/json" --input "/path/to/payload.json"
```

Verify each returned or fetched note has the intended body and non-null position with the expected
paths, side, and line; inspect its line code where exposed. Record the created IDs.

After a timeout or ambiguous response, list drafts and reconcile before retrying. Retry only after
confirming the note was not created or correcting a diagnosed payload error. If you cannot determine
whether the write succeeded, stop that write and report uncertainty. Correct a stray note created
by this run only when its ID and ownership are certain; preserve pre-existing drafts.

Report created, reused, and unanchored findings and any failures. Never call the publish endpoints
as part of creating drafts.
