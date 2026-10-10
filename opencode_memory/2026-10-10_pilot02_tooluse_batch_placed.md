# 2026-10-10 — Pilot02 O20/O29 tool-use batch constructed by PM and placed in repo

## What happened

PM constructed the pilot02 tool-use batch from the completed fixture
(commit `7d93cf54`) and handed it back in `/data/agentic_trading/training_pilot/`.
Placed (moved) into `training_data/derived/training_pilot/`, commit `9f6896eb`, pushed.

## Batch contents (verified on disk)

- `sft_trajectories.jsonl` — 3: pilot02_o20_binding, pilot02_o29_measure,
  pilot02_o20_probe_recovery. Fields: id, tools, messages,
  assistant_loss_mask (one bool per message), metadata.
- `preference_pairs.jsonl` — 5: o20_binding_act, o29_measure_act, o20_report,
  o29_report, o20_probe_recover. Fields: id, tools, prompt, chosen, rejected,
  metadata. Shared-prompt pairs; preference loss applies to the continuation
  only, never the shared prefix.
- `replay_fixtures.jsonl` — 8 command→result mappings (o20_inventory,
  o20_dispatch, o20_scope, o20_provider, o29_counts, o20_failed_probe,
  o20_tail, o20_binding). Exact-string replay only; no shell fallback.
  `o20_binding` is a NEW command whose output is a deterministic projection
  of the 7 supplied raw first-assistant entries — not a claimed historical call.
- `manifest.json` — counts, attachment sha b5edd733…, per-file shas
  (verified PASS), split "training", excluded_gold O20.2/O20.7/O29.4/O29.5/O29.6,
  3 claim boundaries, fixture_commit_reported [6df64484, 7d93cf54].
- `check_and_replay.py` — stdlib-only; PASS (exit 0): replay, message linkage,
  masks, file hashes. No shell commands executed.
- `README.md` — usage rules (see below).

## Checks I ran (all PASS)

- Manifest per-file sha256 vs actual: 3/3.
- check_and_replay.py: PASS.
- Loss-mask invariant: mask=True only on assistant messages, all 3 trajectories;
  recovery prefix [1] = failed probe with mask=0 (explicitly masked per spec),
  [3] tail-check call mask=1, [5] answer mask=1.
- Message/mask length alignment: 12/12, 4/4, 6/6.

## Standing rules from the batch README (do not forget)

- Two families (O20, O29), NOT eight independent examples; SFT↔preference
  overlap must be accounted for when assembling the full pilot.
- Only `tools` + `messages` (SFT) or `tools` + `prompt` + continuation
  (preference) are model input. Metadata, IDs, provenance, masks = loader
  controls, never model input.
- Neutral function-tool messages; BEFORE the GPU pilot: convert with the
  selected checkpoint's actual tool/chat template and verify serialized
  call arguments, role boundaries, per-token masks, lengths, truncation;
  include `tools` in serialized context; never treat tool calls as empty text.
- Replay is validation, not a free-generation evaluator.
- Historical narrative answers with broader unsupported claims (O20.2/O20.7/
  O29.4) are excluded gold; teacher answers are deliberately narrower.
- No model trained or evaluated on these yet; GPU training not started.

## State

- Pilot03 batch closed and unchanged (6 records, assignment pending PM).
- Pilot01 (12 PM synthetic) + training export (37 organic) unchanged.
- Next phase: per PM, "training_pilot has the next phase" — serialization/
  template verification against the selected model before any training.

## Files

- Repo: `/data/agentic_trading/training_data/derived/training_pilot/` (7 files)
- Commits: `6df64484` + `7d93cf54` (fixture completion), `9f6896eb` (placement)
