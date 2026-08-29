# 2026-08-29 — SQLMesh weekly-IV substrate: M2 `iv_weekly_percentile` built + promoted, build complete

**Session:** opencode architect/validator seat (cwd /home/user/oc-ask). Companion sessions:
M1 history `ses_fb5c7f0f3ffe8xmHANRNWzgvIX` / `ses_fb5a34efcffefN6tDs6dfX7JQ0` /
`ses_fbdeafe80ffe0V9oJg4sDVsmlG`; M2 builder dispatch `ses_fb47d3530ffexEM9RNMInoOzyf`;
independent verification pass `ses_fb2de984affeVYTG3tkP5R4Km5`.

## What it is

The second and final model of the weekly-IV substrate (iron-fly L1 conditional-entry data
dependency). M1 `iv_weekly_state_daily` was already promoted (prior session). This session:
wrote the M2 blueprint, drove M2 through all four gates, and promoted it to prod. **The build
(M1+M2) is now complete.**

## Outcome: M2 in prod, all gates green, NO deviation

| Gate | Result |
|---|---|
| Gate-0 | PASS — kept `manual_verification` bypass (OQ-2), updated note + S5 KASA replacement (OQ-1) |
| Gate-1 | builder dispatch `outcome=ok`, 42 msgs/670s, 3 artifacts; KASA 6/6 (my run) |
| Gate-2 | CERTIFIED, all 6 validation booleans true |
| Gate-3 dev | `m2_dev` env, 6/6 post-write PASS |
| Gate-3 prod | rc=0, token consumed, **6/6 post-write PASS** (SNAPSHOT_DELTA_CLEAN + OPERATION_SUCCEEDED) |

## Key facts settled

- **Blueprint:** `.ai/inbox/blueprint_iv_weekly_percentile_m2.md` (PM-ratified). Chunks 0-5.
- **OQ-1 (RATIFIED):** spec's original reconciliation KASA was infeasible (2024-02-05 ref cell
  NULL; wk1/wk2 252d all-NULL in window). Replaced with monthly frozen 252d KA + Pin 6
  bit-faithfulness to `iv_percentile_daily._compute`.
- **OQ-2 (NOT ratified as recommended → keep bypass):** PM found the `columns=[...]` model-file
  edit is NOT fingerprint-inert — `sqlmesh/core/model/definition.py:1173-1175` feeds
  `columns_to_types_` into `data_hash`. Kept the `manual_verification` bypass with an updated
  note instead. **M1 model file untouched** (sha256 `3da25b26…` certified).
- **F10 (warm-up math, load-bearing):** on the real M1 spine, wk1/wk2 `iv_pct_252d`/`iv_rank_252d`
  are ALL NULL in the current window (< 252 valid sessions each); monthly first-valid 2024-05-24.
  This is data, not a defect.
- **Frozen KAs (full float repr):** monthly 2025-01-06 iv_pct_252d=0.43253968253968256,
  iv_rank_252d=0.16394072745371488, atm_put_iv=0.123141; plus 10/20/60d per bucket (see spec S5).

## Artifacts (certified, repo + workdir byte-identical)

- model `warehouse/models/iv_weekly_percentile.py` sha256 `76b8307a…` (FULL python, 12 cols, 4 audits)
- test `tests/test_warehouse_iv_weekly_percentile_kasa.py` sha256 `0e3a02be…` (dual-mode, 6 tests)
- receipt `BUILDER_RECEIPT.json` sha256 `cae14cc8…` (certified)
- spec `.ai/inbox/build_spec_iv_weekly_percentile_gate0.md` sha256 `9d45403e…` (final)

## Prod state (verified read-only)

M2: 3,192 rows = 1,064 trade_dates × 3 buckets, 2022-06-01..2026-08-27. M1 unchanged (3,192).
Token `pm_m2_iv_weekly_percentile_20260829T104357Z` consumed (replay blocked).

## Evidence (canonical)

- Gate-3: `verify/m2_gate3_20260829T104500Z/` (baseline, dry-run, token draft+ratified,
  operation result, post-write report, closeout).
- verify-run transcripts: `verify/m2_chunk0_*`, `m2_chunk1_staging.*`, `m2_gate1_kasa_*`,
  `m2_gate2_certification.*`, `m2_gate3_devplan.*`, `m2_gate3_prodwrite.*`, `m2_gate3_prod_postverify.*`.

## Standing rule honored (the M1 lesson)

The M1 transient state-DB migration error did NOT recur. Rule in force throughout: executor
non-zero exit ⇒ stop and report, NO out-of-band re-run. Not needed — prod write was clean rc=0.

## Dispatch mechanics that worked (for next time)

- Detached launch: `nohup … & > log 2>&1` so the 120s bash cap can't kill a 15-45min run;
  poll via `dispatch_meta.json` + opencode-server `/session` (auth `opencode:<pw>`), not by
  holding the process.
- `--stall 720` (M2's M1 re-derivation is slower than M1's). `--agent sqlmesh-builder` MUST be
  forwarded (a prior M1 re-fire dropped it → ran as default `ask`).
- Executor `plan`/`run` flags need a `--` separator (its argparse eats `--create-from` etc.).
- Workdir is a SEPARATE checkout; executor runs the REPO project, so promote model+test to the
  repo (untracked, M1 precedent) before the dev plan.
- Scope prod writes with `--select-model` (repo has dirty `iron_fly_v2.sql` — avoid promoting it).

## Registration disposition (O1, inherited from M1)

M2 is a warehouse DuckDB table, not a /data/parquet dataset → no POOL_LEDGER/data_catalog entry.
Authoritative registration = the SQLMesh model file (untracked in git, same as M1).

## Open / next

- None blocking. The IV weekly substrate build is complete.
- Residual (PM-owned, non-blocking, from M1): 0.236.0→0.236.1 `_versions` drift; no guarded
  dev-env-cleanup path (`m2_dev` + M1's `dev_timing` remain).
- When wk1/wk2 accumulate 252 valid sessions (~2026-06/07+), the cross-table value
  reconciliation vs `iv_percentile_daily` becomes meaningful — revisit then (OQ-1 note).
