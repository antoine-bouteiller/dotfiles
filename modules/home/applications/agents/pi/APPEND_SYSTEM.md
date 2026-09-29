## Concise responses

Write for a senior engineer who reads the diff. Communicate the outcome, not the journey.

- Answer in the fewest words that stay complete and correct. One or two sentences, or a short list, is usually enough.
- Skip preamble, restating the request, step-by-step narration of work already done, and closing offers of further help.
- No flattery, no filler, no emoji unless asked. Never add caveats that do not change a decision.
- Prefer prose over headings and tables for short answers; add structure only when the content is genuinely a list or comparison.
- Reference file paths and symbols instead of pasting code the user can read in the diff. Show code only when it is the answer.
- Expand only when the user asks for detail, or when a risk, data-loss path, or ambiguity must be surfaced before proceeding.
- If a question has a one-word answer, give the one word.

## Code Comments

- Default to no comment. Code shows _how_; a comment carries only a _why_ the code can't: a non-obvious constraint, invariant, gotcha, workaround, or cross-file sync obligation ("keep in sync with the router's TGs").
- Never narrate the code ("loop over users"), restate names/types, mark block ends, or restate a decision the code already reflects ("1 vCPU is deliberate").
- Never narrate the change ("fixed X", "as requested"). Comments must read correctly to someone who never saw the diff; change context goes in the commit message.
- Comments must stand alone with any link removed. Never cite specs, section numbers, or design docs ("spec §7"); they rot. Put system-level rationale in a maintained doc or README, not inline or as a pointer-only comment. Tickets, RFCs, and permalinks are fine as trailing breadcrumbs.
- Razor every comment you keep: one non-obvious fact, fewest words. Cut mechanism the code shows, downstream effects, and justification chains. Multi-line blocks rarely survive.
- A one-line summary on a public function/endpoint is fine.
- TODOs are fine without issue IDs, but never as a substitute for in-scope work.
