# 2026-09-04 — Pi loop-guard extension (repetition backstop for AGENTS.md budget rule)

## What was built

`~/.pi/agent/extensions/loop-guard.ts` (67 lines) — a Pi extension that interrupts
verbatim reasoning loops in pi-seat models, as a harness-level backstop for AGENTS.md
execution rule 3 (the 5+3 probe budget). Built by qwen-coder (BUILD mission), content
verified byte-exact by the main seat (Read of all 67 lines).

**Why:** qwen3.8 in a pi seat looped ~20× on one question (9/3 A1_EMERGENT vs
A2_PERSISTENT classification) — re-deriving the same "DISCREPANCY" conclusion with
zero tool calls, each pass ending in "let me check cohort_map_builder.py" without
ever checking it. Root cause: the budget rule counts *probes* (tool calls); the loop
made 0 probes, so the rule never fired, and a 27B model cannot self-detect
"am I making progress" in its own reasoning tokens.

## How it works (the shape)

- Unit = **cycle**: same 8-word shingle (exact, case/punctuation-sensitive)
  reappearing in the cumulative assistant message text. Paraphrase never counts.
- Thresholds mirror the doctrine 1:1: cycles 1–4 nothing; cycle 5 = `ctx.ui.notify`
  warning to the HUMAN only (no model intervention); cycles 6–7 grace; cycle 8 =
  `pi.sendUserMessage(..., { deliverAs: "steer" })` — an interrupt mid-stream with
  the two honest exits: "make the tool call you said you'd make, or state BLOCKED
  with the exact missing input."
- `tool_execution_start` resets the counter (a tool call = the commit the budget
  demands → fresh 5+3). `turn_end` resets the once-per-turn `steerSent` flag.
- Steer fires at most once per turn/message.

## Load path (verified, not assumed)

`loader.js:628` (`discoverAndLoadExtensions`): global extensions dir =
`agentDir/extensions/`, rule 1 = direct `*.ts` files load. So the file is
**auto-loaded in every pi session** — no `-e` flag needed. (The file header says
`pi -e ...`; that's redundant but harmless.)

## UNVERIFIED / watch for unintended consequences

1. **`AgentMessage.content` shape is a guess.** `textOf` assumes
   `content: {type:"text", text}[]` or string. If pi's actual shape differs, the
   detector silently sees empty text and never fires (fail-safe, not fail-danger).
   Confirm by logging one real `message_update` payload.
2. **`steer` while streaming** — assumed to interrupt per the
   `send-user-message.ts` example; not yet exercised by a real loop.
3. **False-positive surface:** any legitimate assistant message containing the same
   8 verbatim words ≥8× (quoting a repeated block, e.g. a loop transcript itself —
   this very session's context) will trigger the steer. The steer is a user-role
   message, so it pollutes the conversation; at worst it's a nudge the model can
   ignore.
4. **Per-message scope:** cross-turn loops (one copy per message) are NOT caught;
   only within-one-assistant-message verbatim runaway.
5. **Applies to ALL pi seats** (global dir), not just qwen3.8. If a seat's normal
   output legitimately repeats 8-word blocks (templates, SQL), the warning at cycle
   5 will be noise. Lower `WARN_AT`/`STEER_AT` (lines 21–22) or delete the file to
   disable.
6. `message_update` handler recomputes the full shingle map per token — O(n) per
   update; fine at session scale, would matter only for pathological multi-100k-word
   single messages.

## Related decisions from this thread

- The 9/3 classification itself: qwen-coder EXPLORE resolved it — the code
  (`cohort_map_builder.py:26` `OPEN_CAPTURES=[940,950,1000,1010]`, lines 210–213)
  takes `body_rank_open = min(rank over 09:40–10:10)`; 9/3 was rank 1 at 09:40 →
  `body_rank_open=1` → A2_PERSISTENT per code. Design discrepancy vs the report's
  semantic "minor at open" (which used 09:00–09:30). 9/2 has no body_strike in
  runner_features_v3.parquet → unclassifiable.
- Fix ladder agreed: (1) AGENTS.md rules 5a/5b (re-derivation budget + "intention
  is not an action") — NOT yet applied to AGENTS.md, PM call; (2) put code
  definitions in the GROUNDING field of dispatch envelopes; (3) this harness
  backstop — APPLIED.

## Files

- `~/.pi/agent/extensions/loop-guard.ts` — the extension (new)
- `/data/agentic_trading/analysis/sml_fly_verify/gamma_topology/cohort_map_builder.py:26,210-213` — the classification logic the loop was about
