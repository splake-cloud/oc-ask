# 2026-08-30 — IV backfill-to-2021: Gate-3 staging packet built, M2 discrepancy ADJUDICATED (verdict STOP → PASS)

**Session:** opencode architect/validator seat (cwd /home/user/oc-ask), `ses_fb1efa917ffeSS6g82KUZw5POe`.
Packet build by qwen38-delegate (resumed packet-build session, scratch copy kept in
`/var/tmp/ivw_gate3_staging/`). Spec: `studies/iv_weekly_substrate/specs/build_spec_iv_backfill_gate3_staging.md`.
Packet: `/data/agentic_trading/verify/iv_backfill_gate3_20260830T001926Z/` (8 artifacts).

## What it is

Gate-3 staging for the IV weekly substrate backfill to 2021-05-13 (continues
`2026-08-29_iv_backfill_2021_gate1_applied.md`: Gate-1 C1–C8 applied, Gate-2 carrier KASA PASS).
Staging = the pre-write packet: row baseline, metadata baseline, NON-APPLYING plan build on a
scratch state-DB copy, plan explanation + validation, post-write + KASA invocation docs.
**No prod write** — the write itself remains a separate PM-token-gated step.

## The M2 discrepancy — ADJUDICATED (the STOP cause, resolved)

The 00:19 packet build STOPped: the measured NON-APPLYING plan assigned M2
(`iv_weekly_percentile`) version FIELD **2902785128** (carried over,
**INDIRECT_NON_BREAKING**), not the spec §2.4 expectation of **3013756842 /
FORWARD_ONLY_NON_BREAKING**. Adjudication (3.8, then independently receipt-reviewed by this
seat against the raw plan + installed source): **spec expectation was wrong; the plan is
correct and safe.**

- **The safety question (stale or re-materialized?): re-materialized.** M2 is a FULL model
  (`warehouse/models/iv_weekly_percentile.py:109`) whose `execute()` reads the WHOLE M1 table
  with no date filter (`:132-135`), and M2 IS in the plan's backfill set over 2020-08-03 →
  frontier (raw plan `intervals = [[1596412800000, 1787875200000]]`). The write re-runs M2
  over the new M1 → full re-derivation (3,990 rows incl. 2021 history), NOT the stale 3,192.
- **Why the version FIELD carries over (correct SQLMesh behavior):** `Snapshot.categorize_as`
  (`.venv/.../sqlmesh/core/snapshot/definition.py:1134-1144`): `is_no_rebuild = forward_only
  or category in (INDIRECT_NON_BREAKING, METADATA)` → `elif is_no_rebuild and
  self.previous_version: self.version = self.previous_version.data_version.version`. M2's only
  directly-modified parent (M1) is NON_BREAKING → indirect path at
  `core/plan/builder.py:752-755` assigns INDIRECT_NON_BREAKING → version FIELD = previous
  2902785128, in-place re-materialization of physical table
  `warehouse__iv_weekly_percentile__2902785128`. `to_version()` = 3013756842 is
  fingerprint-derived and reference-only. **FORWARD_ONLY is deprecated** (asserted at
  definition.py:1129) — it was never the right category.
- **Spec error root cause:** §2.4 derived the expectation from `to_version()` instead of the
  snapshot's version FIELD. (First qwen-coder plan build also reported 2902785128; the
  3013756842 "correction" overrode it in error.)
- **Parent cascade is real:** M2 `parent_data_hash` 3222824531 → 1695153442; reproduced
  exactly: `hash_data(["3018527636"]) = 1695153442` (new M1 version). M2's own data_hash
  (2405204001) / metadata_hash (953985241) unchanged; M2 file unchanged in working tree.

## Receipt review (this seat, against primary evidence — not the report)

All load-bearing facts re-verified from `/var/tmp/ivw_gate3_staging/plan_result.json` (raw
plan) + installed sqlmesh 0.236.1 source + M2 model source. Fresh transcript:
`verify/gate3_m2_adjudication_evidence.20260830T030613Z.txt` (exit 0). Measured transitions:
calendar 2127916289→617669567 (NON_BREAKING); M1 4225993480→3018527636 (NON_BREAKING,
backfill from 2021-05-13); M2 2902785128 carried (INDIRECT_NON_BREAKING). `restatements=[]`,
`restate_all_snapshots=False`, `allow_destructive_models=[]` — no interval wipe, no
destructive change, exactly 3 models.

## Packet verdict: PASS (was STOP)

| Artifact | Status |
|---|---|
| `00_calendar_c1_proof.md` | PASS — single stamp diff; 9,318 rows / 1990-01-02→2026-12-31 |
| `01_m1_row_baseline.parquet` | PASS — 3,192 rows / 11 cols / min 2022-06-01; sha256 `eae18912…` |
| `02_staging_metadata.json` + `02b_metadata_baseline.json` | PASS — pre-write ids match §2.1; M2 planned transition = adjudicated |
| `03_plan_explanation.md` | PASS — NON-APPLYING; scratch copy sha256 BEFORE==AFTER; M2 RESOLVED |
| `04_plan_validation.md` | PASS — I2/I3/**I4 (adjudicated)**/I5 all hold |
| `05_postwrite_invocation.md` | PASS — `--expect-changed {nyse_calendar, iv_weekly_percentile}`; NOT executed |
| `06_kasa_invocation.md` | PASS — pytest/explicit call required (no `__main__` trap); no KASA run |
| `08_staging_report.md` | PASS — overall |

**Prod-unchanged proof:** `/data/warehouse/warehouse.duckdb` sha256
`386140b3dda81ed611de329848a50123a2b6f5af683bd0ebffe6f66a5bc3d101` BEFORE == AFTER ==
re-checked at review time. No token minted/consumed, no physical write, no promotion.

**D9 upper bound closed (Part C):** `scripts/post_write_verify.py` `check_row_idempotency`
now bounds the compare to `trade_date <= baseline_max` (baseline's own max) and reports
(not fails) frontier rows past it (`post_write_verify.py:366-421`). Behavior-preserving when
the frontier has not advanced. py_compile OK + targeted fake-data tests (frontier advance →
PASS+report; altered row → FAIL; no advance → PASS).

## Corrections applied (transpositional)

- Spec: §2.4 row + M2 bullet, I4, E3, Chunk-3/4 expectations, §8 AC4 — all M2 references now
  "version FIELD 2902785128 carried over / INDIRECT_NON_BREAKING / in-place re-materialization;
  to_version() = 3013756842 fingerprint-derived, reference only". Zero `FORWARD_ONLY` left;
  all six `3013756842` mentions marked reference-only.
- Packet: `02`/`03`/`04`/`08` as above.

## Traps (record for future sessions)

- **Scratch state-DB copy MUST be named `warehouse.duckdb`** (catalog = filename stem). First
  staging build used `state_copy.duckdb` → snapshots fingerprinted under catalog
  `state_copy`, M2 metadata_hash wrong (4156207805 vs 953985241), models looked brand-new.
  Same class as the Gate-2 carrier-filename finding (F1) — a third occurrence of the
  catalog-stem rule.
- `verify-run` needs the command as `prog args…`, not a `python3 -c "…"` string (line 26
  treats argv[1] as a path) — write a probe script to `/tmp/opencode/` instead.

## Next

PM-token-gated prod write: single scoped `plan prod` `[nyse_calendar, iv_weekly_state_daily,
iv_weekly_percentile]` (one-use token, `--auto-apply --no-prompts`); post-write
`post_write_verify.py --model warehouse.iv_weekly_state_daily --expect-changed
warehouse.nyse_calendar,warehouse.iv_weekly_percentile --row-baseline
01_m1_row_baseline.parquet` (SNAPSHOT_DELTA_CLEAN = exactly those 3; ROW_IDEMPOTENCY
set-equal bounded to ≤ baseline_max 2026-08-27); final KASA on the default prod path
(pytest/explicit call — never bare `python3 <file>` on the M1 KASA).
