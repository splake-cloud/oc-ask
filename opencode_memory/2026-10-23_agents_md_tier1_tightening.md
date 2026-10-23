# 2026-10-23 — AGENTS.md Tier-1 tightening + 46.2M-token delegate-burn root cause

Pi session `01a166b3-5d0b-7222-bbbb-4bac38382878` (jett-8012/qwen3.8-27b-fp8, /data/agentic_trading).

## Token-burn root cause

PM asked why a session burned 20k+ tokens on "prefill". Pulling the transcript
(`~/.pi/agent/sessions/--data-agentic_trading--/2026-10-23T02-33-34-246Z_01a1669b….jsonl`,
qwen3.8-27b-fp8-instruct / :8081-instruct delegate, ontology_actions.py EDIT mission):

- Prefill was innocent: ~3.5k-char dispatch envelope + ~30k AGENTS.md + system prompt ≈ 4.2k tokens.
- The burn: from transcript line 45 to 1006 (~230 turns) the model alternated the **same two
  calls** — `grep -n "def _tx" -A 30 …` + `read … offset 113 limit 26` — ~115 repetitions,
  identical args and ~1.3k result, surviving a compaction at line 817 (loop resumed unchanged).
- Context grew to ~180k; total billed **46.2M input+output tokens** (sum of per-turn usage).
- The edit itself completed (gate helper at `ontology_actions.py:180`, call at :1009) — the
  loop ran *after* the deliverable, stuck assembling verification, never escaping.
- Failure class: degenerate 2-call loop with no self-correction; **no harness guard** (no
  max-turns, no duplicate-call detection) stopped it. Every ~300-450-token turn was paid on a
  growing context — the AGENTS.md size multiplies across all of it.

## AGENTS.md Tier-1 tightening (applied)

30,352 → 27,792 bytes (~650 tokens/session-start, × every turn):

1. **Buried-commit procedure** → `scripts/git-buried-commit.sh` (AGENT_PRINT env for trailer).
   Tested vs a throwaway bare remote (publishes only session paths, leaves intervening
   commits unpublished, local tree untouched, trailer correct). Dogfooded for its own publish.
2. **Model evaluation runs** section → `docs/model-kb/pi_model_eval_runbook.md` (verbatim
   content, 16-fragment check); AGENTS.md keeps a 3-line pointer with load-bearing invariants.
3. **Session memory** section compressed (Codex bullet, proactive-receipts merge, HTML comment).

Published as `ee07135b8` on agentic_trading origin/master (3 files, blobs verified).

## Open items

- Tiers 2 (dedupe ~1.5k bytes) and 3 (rationale compression ~1.8k bytes) of the AGENTS.md
  review not yet applied — PM to decide.
- Harness guard against degenerate delegate loops (max-turns / duplicate-call detection) —
  not built; this card is the evidence base for that decision.
- oc-ask memory repo was diverged (4 local-only commits, all content-identical to origin;
  19 INDEX-linked card files never committed) — reconciled + published same day (wan22 card
  deletion confirmed intentional by PM).
