---
name: publish-draft-review
description:
  Create unpublished inline DRAFT review comments on a GitLab merge request diff via the
  GitLab API. Use when a code review has produced findings that should be attached to exact
  diff lines as drafts (not published) so the human can review and submit them in one batch.
---

# Publish Draft Review

Posts inline **draft notes** (unpublished review comments) onto a GitLab MR diff, anchored to
exact file:line positions. Drafts are visible only to the author until the GitLab "Submit review"
button (or the `bulk_publish` endpoint) is pressed — nothing is published by this skill.

## Hard-won mechanism (read before posting — these footguns cost real time)

1. **Use a JSON request body via `--input <FILE>`, never `-f "position[...]"`.**
   `glab api -f` flattens form fields and the nested `position` object comes back **null** — the
   note is created but as a *general* (non-inline) draft. The position object MUST be sent as a
   JSON body.
2. **`--input -` (stdin) is unreliable here. Use a real file path.** Piping the JSON into
   `glab api --input -` inside a function/heredoc produced empty bodies / parse errors. Writing
   the payload to a file and passing the path works every time.
3. **This environment's shell PATH is minimal.** `jq`, `mktemp`, `rm`, sometimes `python3` are
   "command not found". Call binaries by absolute path: `jq` at `/run/current-system/sw/bin/jq`,
   `glab` at `/run/current-system/sw/bin/glab` (verify with `command -v` first). Avoid
   `mktemp`/`rm`/`cp` — write payload files with the **Write tool** instead.
4. **Anchor only to lines that appear inside a diff hunk.** GitLab cannot attach a comment to a
   line outside the diff. Prefer **added** lines (prefixed `+`): their position needs only
   `new_path` + `new_line`. For **context** lines you must also supply `old_line` (compute by
   walking the hunk headers). If the line you want is outside any hunk, anchor to the nearest
   added line and reference the real line in the comment text.
5. **Get `diff_refs` from the MR, not from local git.** `base_sha` / `start_sha` / `head_sha`
   come from `GET projects/:id/merge_requests/:iid`.

## Generic workflow

```bash
JQ=/run/current-system/sw/bin/jq
GLAB=/run/current-system/sw/bin/glab

# 1. Identify the MR + diff refs
$GLAB mr view                                   # MR number for current branch
$GLAB api "projects/:id/merge_requests/<IID>" | $JQ '{project_id, diff_refs, sha}'

# 2. For each finding, write a payload JSON FILE (use the Write tool, not shell heredocs):
#    { "note": "...markdown...",
#      "position": { base_sha, start_sha, head_sha, position_type:"text",
#                    old_path, new_path, new_line } }
#    old_path == new_path for added/context lines. Add "old_line" for context lines.

# 3. POST each as a draft note:
$GLAB api --method POST "projects/<PID>/merge_requests/<IID>/draft_notes" \
  --header "Content-Type: application/json" --input "/path/to/payload.json" \
  | $JQ -r 'if .id then "OK draft \(.id) @ \(.position.new_path):\(.position.new_line)" else "FAIL \(tostring)" end'

# 4. Verify (look for non-null line_code = correctly anchored inline):
$GLAB api "projects/<PID>/merge_requests/<IID>/draft_notes" \
  | $JQ -r '.[]|"\(.id) \(.position.new_path):\(.position.new_line) line_code=\(.line_code)"'

# 5. (Only when the human says so) publish all drafts at once:
# $GLAB api --method POST "projects/<PID>/merge_requests/<IID>/draft_notes/bulk_publish"

# Delete a stray draft:
# $GLAB api --method DELETE "projects/<PID>/merge_requests/<IID>/draft_notes/<NOTE_ID>"
```
