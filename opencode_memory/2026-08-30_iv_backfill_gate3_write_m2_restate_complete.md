# 2026-08-30 — IV backfill-to-2021: Gate-3 WRITE executed + M2 stale defect found & fixed — COMPLETE

**Session:** opencode architect/validator seat (cwd /home/user/oc-ask), `ses_fb1efa917ffeSS6g82KUZw5POe`.
Continues `2026-08-30_iv_backfill_gate3_staging_m2_adjudicated.md` (staging PASS) and
`2026-08-29_iv_backfill_2021_gate1_applied.md` (Gate-1/2). **The IV backfill to 2021-05-13 is COMPLETE.**

## What happened (the full Gate-3 write arc)

1. **Pre-write state check** (P1–P8, `gate3_prewrite_state_check*.txt`) — PASS; prod sha256 invariant;
   pool frontier advanced 2026-08-27→28 (D9, re-measure at write time).
2. **Data-access plan assessment + independent qwen-coder verification** (8 PASS/1 PARTIAL,
   `studies/iv_weekly_substrate/receipts/2026-08-30_gate3_data_access_plan_assessment.md`):
   read-only, bounded, **single full-window scan** (scheduler merges contiguous daily intervals,
   `batch_size=None`), no concurrent writer (cron `--skip-shadow` skips the state-DB step),
   `hive_partitioning=false` → no file-level path prune (75 s glob-open, amortized over one scan),
   projection pushdown on. **C9 escalation: run host-side** (opencode-server cgroup `memory.max`=8 GB
   < `max_memory`=16 GB). Vantage confirmed host (netns 4026531833, cgroup memory.max=max).
3. **Write #1** (token `pm_ivw_backfill_2021_gate3_20260830T122149Z`, 3-model `plan prod`):
   executor exit 0. M1 → 3018527636 (3,987 rows, 2021-05-13..27, baseline preserved — all 7
   `post_write_verify` PASS); calendar → 617669567. **BUT M2 = 3,192 rows, 2022-06-01.., 0 rows in
   2021 — STALE.** 795 M1 keys missing from M2.
4. **Defect root cause — the staging adjudication inverted `is_no_rebuild`.**
   `definition.py:1134`: `is_no_rebuild = forward_only or category in (INDIRECT_NON_BREAKING, METADATA)`;
   for M2 (INDIRECT_NON_BREAKING) that branch sets `self.version = previous_version` — i.e. **NO
   REBUILD, reuse the old table as-is**. The adjudication read "carried-over version" as
   "in-place re-materialization"; it actually means "do not rebuild." So M2 was never re-run.
   (The "data not stale" claim in the staging card is WRONG for the write — corrected here.)
5. **Write #2 — M2 restate** (token `…m2_restate_20260830T124650Z`, `--restate-model
   warehouse.iv_weekly_percentile`, PM ran by hand). M2 re-materialized: **3,987 rows,
   2021-05-13..27, M1 keys missing = 0, 795 rows in 2021 span**. M1 + calendar snapshot IDs
   UNCHANGED. M2 KASA (default prod path) PASS; M1 KASA (explicit call) PASS.

## Final verified state (all 3 models)
| Model | version | rows | range |
|---|---|---|---|
| `iv_weekly_state_daily` (M1) | 3018527636 | 3,987 | 2021-05-13..2026-08-27 |
| `iv_weekly_percentile` (M2) | 2902785128 (carried) | 3,987 | 2021-05-13..2026-08-27 |
| `nyse_calendar` | 617669567 | 9,318 | 1990-01-02..2026-12-31 |

## Traps / lessons (record for future sessions)
- **`is_no_rebuild` = "do NOT rebuild," not "rebuild in place."** A carried-over version FIELD on an
  INDIRECT_NON_BREAKING FULL model means the old physical table is REUSED, not re-materialized. If
  the intent is to re-derive a FULL child over a changed parent, you must **restate** it
  (`--restate-model`); a plain `plan prod` will NOT re-run it. This is the general rule: an
  indirectly-modified FULL model needs an explicit restate to pick up parent data changes.
- **The "single full-window scan" cost model is right** (one batch, `batch_size=None`); the defect
  was in M2's *execution* (no rebuild), not in the scan strategy.
- **Token `command_hash` collapses repeated `--select-model`** to the last value
  (`normalize_argv` dict-keyed flags) — the real scope binding is the token `models` list via
  `enforce_model_scope`. Don't treat the hash as model-scope proof.
- **Registry path is `.sqlmesh_runtime/token_registry.json`** (NOT `.guarded_runtime/`); a P-check
  that looked at the wrong path reported "no token ever consumed" when 19+ had been.
- M2 KASA has `__main__` (bare `python3` OK); M1 KASA does NOT (must call
  `test_iv_weekly_state_known_answers()` explicitly).

## Evidence (repo-root `verify/iv_backfill_gate3_20260830T001926Z/`)
`09_token_ratified.json` (write #1), `10_operation_result.json`, `11_postwrite_report.json` (M1 PASS),
`12_deviation_record_m2_stale.md` (defect + RESOLUTION), `13_token_m2_restate.json` (write #2),
transcripts `gate3_m2_restate_postwrite.*.txt` (exit 0), `gate3_postwrite_m2_stale_evidence.*.txt`.

## Next
Nothing blocking — the substrate is backfilled to 2021-05-13 and all three models verified.
Consumers (iron-fly L1 conditional-entry) can now use the extended history. The 2026-08-28 frontier
day is picked up by the next daily cron (M1 INCREMENTAL).
