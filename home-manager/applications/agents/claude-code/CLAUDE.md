# System & Workflow Directives

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

## 5. Codebase Exploration Strategy

**Never run `rg`, `grep`, `ag`, `cat`, `sed`, `head` or `tail` against source files.** Text search over
code is a last resort, not a default.

**Load LSP before you start exploring.** It is a deferred tool — its schema is not in context at session
start, so calling it costs `ToolSearch("select:LSP")` first. Pay that once, up front, or the friction
will silently push you back to `grep` every time.

### Tool by question

| Question                              | Tool                                      | If unavailable  |
| ------------------------------------- | ----------------------------------------- | --------------- |
| Who calls / references `X`?           | LSP `findReferences` / `incomingCalls`    | `ast-grep`      |
| Where is `X` defined? What type?      | LSP `goToDefinition` / `hover`            | `fff` grep      |
| What symbols does this file export?   | LSP `documentSymbol`                      | `outline` skill |
| Where in the repo is a symbol named…? | LSP `workspaceSymbol`                     | `fff` grep      |
| Find a code _shape_ / API misuse      | `ast-grep`                                | LSP             |
| Which files exist for topic Y?        | `fff` `find_files`                        | `Glob`          |
| Text/identifier across many files     | `fff` `grep` / `multi_grep`               | `Grep` tool     |
| File contents                         | `Read` (use `offset`/`limit` for a slice) | —               |

### Rules

- **Never silently fall back to `grep`.** `fff` is an MCP server and _does_ disconnect mid-session. When
  it drops, go to `ast-grep` or LSP — not to Bash.
- **Prefer LSP over `fff`/`ast-grep` for anything about symbols.** Only LSP resolves re-exports, aliased
  imports and type relationships. Grep silently misses them, and mixes code hits with prose hits from
  `*.md`.
- Text search _is_ correct for: prose (`*.md`, specs, comments-only sweeps), `node_modules` build output
  and other unindexed files, and logs. Use the `Grep` tool over Bash `grep` even then.
- Two tools would both work? Take the more precise one and move on — this is a reflex, not a research
  project.
- After ~2 searches you have enough paths. `Read` the code instead of grepping variations.

## 6. RTK — Rust Token Killer

RTK optimizes terminal outputs to save tokens. Standard commands (e.g. `git status`) are automatically hooked — just run them normally.

### Bypassing RTK

If an output is truncated by the hook and you need the raw, unfiltered information, use the proxy:

```bash
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```
