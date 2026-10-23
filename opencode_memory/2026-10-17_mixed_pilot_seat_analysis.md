# 2026-10-17 — Mixed public-evidence pilot: seat analysis (runner + content pipeline)

Diagnosis of the 2026-10-17 issues getting the mixed 38-row pilot runner (3 local + 35
public) working, and of the 8081 review/8011 author content pipeline. Question: attribute
each defect to 8081 capability, codex orchestration, harness, or environment.

**Full report: `/data/agentic_trading/training/public_evidence_mixed_pilot_20261017/SEAT_ANALYSIS_20261017.md`**

## Key facts settled

- **Orchestrator record found**: codex thread "Fine-tune Qwen3.8 with datadesigner"
  (`01a13b93…`) — 10-17 activity is APPENDED to the 10-14 rollout file
  `/home/user/.codex/sessions/2026/10/14/rollout-2026-10-14T18-01-30-….jsonl` (95 MB,
  39,874 lines; 10-17 from line index 28744). `sessions/2026/10/17/` does not exist —
  a date-dir search misses the whole thread. `~/.codex/history.jsonl` has the user's own
  log-request (12:42) that started this analysis.
- **Dispatch sequence**: D0 build (10:13, headless pi primary `--model jett-8081
  --no-session`) → D1 corrected build → D2 bounce (out-of-bounds CPU probe) → D3
  (10:49:09, Agent-tool route, killed 56s, wrong-venv premise) → D4 (10:50:38, full-file
  `write`, 3 clause drops + "DELIVERABLE COMPLETE" overclaim) → D5 (10:54:00, targeted
  edits, fixed 2/3 quoted items, new `pub_view._prepare_dataset` AttributeError) → codex
  self-repair 11:01–11:03 (3 of 4 defects) → attempt 1 interrupted 11:05–11:08 (callback
  never registered; SIGINT exit 130, no traceback, silent defect) → one-line fix
  `trainer.add_callback(callback)` (commit `8250a6293`) → retry 11:09:16 **PASS** (20
  steps, checkpoints @10/20, losses 0.3824→0.3544→0.3218).
- **Attribution (per defect, in the report)**: 8081 coder errors on explicit/grounded
  clauses (D0 path/max_steps/saves, D1 omitted local packets, D4 three drops, D5
  one-token API-shape error) vs codex errors (headless-primary dispatch route — admitted;
  AST accepted as check — admitted; scope misjudgment — admitted; envelope gaps for
  known facts: `.venv-training` path omitted from D3 after being used 18 min earlier,
  hash recipe only in the 10-14 log; item-scoped reviews; preflight clause dropped in
  envelope drift) vs harness (stop-propagation failure to child; `pi -p "@qwen-coder"`
  rejected as file attachment; `--no-session` lost D0–D2 audit trail) vs environment
  (dual venv: default python3→`.venv` no-trl vs `.venv-training`; GPU1 occupied by
  gpt-oss-120b).
- **8081-as-coder verdict**: not a capability collapse. Profile: quoted minimal edits →
  compliant; one-shot rewrites of multi-clause contracts → clause drops; failures
  concentrate on last-10% cross-referencing; self-verification unexecuted (AST+grep) →
  overclaims. Consistent with "reliable to act as instructed" for explicit quoted edits.
- **8081-as-reviewer numbers** (recomputed from run files): FAIL precision on retained
  records 3/5 = 60% (both overruled FAILs = multi-conjunct "partially supported"
  framing); recall on retained material errors 3/15 = 20% (10 of 12 held traces were
  reviewer-PASS; 2 of 3 corrected answers reviewer-PASS); one date-case misread
  (FEVEROUS-51592-G1). Triage filter, not verdict authority. Same FP mode as the
  independent set2 sample (10/15 answer FAILs + 5/5 reasoning FAILs overruled there).
- **8011-as-author numbers**: 16/50 first draws (32%) material errors, one failure
  family (plausible completion beyond supplied evidence) in 4 sub-families (out-of-packet
  fill-in ×5, quantity substitution ×4, qualifier strengthening ×4, entity/scope
  conflation ×3). All 16 regenerated answers (delta13+extra3+replacement1) passed
  admission; all 12 reasoning holds from original draws. The error family is exactly the
  behavior under SFT.
- **Interruption confirmed**: no Python traceback; silent defect class that AST, execution
  telemetry, and prep-only preflights all miss — only a trainer-constructing preflight or
  whole-contract review catches it.

## Bankable principles (in the report)

8081 dispatches: mandate `edit` not `write` for big files; quote violated clauses with
line ranges; state facts don't point (venv, hash recipe, step counts); require executed
proof (CPU prep printing actual hash matches); per-clause evidence for "COMPLETE".
Orchestrator: delegate-card route not headless primary; whole-file review after each
edit; verify stop propagation; no `--no-session` on audit-critical dispatches; keep a
trainer-constructing preflight in every iteration.

## Evidence gaps

- D0/D1/D2 sessions unrecoverable (`--no-session`); those defects attributed from codex
  review messages + output artifacts.
- 8081 review-run FP rate varies by sample (40% parallel set, 83–100% set2) — the mode is
  stable, the rate is not yet measurable enough to set a review-trust threshold.

## Next / open

- PM to review the report; possible doctrine additions (preflight requirement, envelope
  "state-don't-point" rule) if ratified.
- The parallel set's 12 held packets remain available for targeted regeneration (per the
  10:12:37 user directive).
