# 2026-08-29 — IV backfill-to-2021: Gate-1 (C1–C8) applied + verified

**Session:** opencode architect/validator seat (cwd /home/user/oc-ask). Companion sessions:
C8 ratification run `ses_fb1efa917ffeSS6g82KUZw5POe` ("IV run: C8 idempotency carrier Gate-1
verification"); Gate-1 builder dispatch `ses_fb1df2f48ffeyc7zPI1klEnI1t` (@qwen-coder 3.6).

## What it is

The IV weekly substrate **backfill to 2021-05-13** (+ `warehouse.nyse_calendar` rebuild to the
1990-extended source). NOT a new-model build — a transpositional parameterization of an already
certified substrate. Spec: `studies/iv_weekly_substrate/specs/build_spec_iv_backfill_2021.md`
(sha256 `e3db3f2af450ac512b04935244638d635298b00a223a57e9ba60c14b104d2101`). This session
staged + dispatched **Gate-1** (the qwen-coder 3.6 transpositional edit) and ran its VERIFICATION
as verify-run events.

## Outcome: Gate-1 APPLIED and VERIFIED (all 8 clauses)

C1–C8 are the ONLY diffs (git diffstat = exactly the 4 files, nothing else). Frozen KAs untouched.

| # | File | Change (verified line) |
|---|---|---|
| C1 | `warehouse/models/nyse_calendar.sql:14` | stamp → `..._20260829_1990ext` |
| C2 | `warehouse/models/iv_weekly_state_daily.sql:70` | `start '2021-05-13'` |
| C3 | `warehouse/models/iv_weekly_state_daily.sql:99` | pool floor `>= DATE '2021-05-13'` |
| C4 | `warehouse/models/iv_weekly_state_daily.sql:48` | comment `start '2021-05-13' (R-1 boundary)` |
| C5 | `tests/test_warehouse_iv_weekly_percentile_kasa.py:65-70` | `WARMUP_FIRST_VALID` re-pinned to §3 measured values |
| C6 | `tests/...percentile_kasa.py:31-34` | warm-up header block dates (10/20/60d + monthly-252d) |
| C7 | `tests/...percentile_kasa.py:53` | `_M1_DB = os.environ.get("IVW_M1_DB", <prod>)` (all 3 uses covered) |
| C8 | `scripts/post_write_verify.py` | additive `--expect-changed` + `--row-baseline` + `check_row_idempotency` (ROW_IDEMPOTENCY) |

## C8 — the load-bearing piece (now in the working tree)

- `check_snapshot_delta_clean(..., expect_changed=None)` — `excluded = {model} | expect_changed`;
  the `added`/`common` set-diff operands changed from `{model}` to `excluded` (behavior-identical
  when the flag is absent). This is what lets the 3-model restatement (calendar + M1 + M2) PASS
  `SNAPSHOT_DELTA_CLEAN` instead of FAILing by naming the two intended companions.
- `check_row_idempotency(...)` — reads the pre-write row baseline parquet, reindexes both frames to
  the baseline's own 11 cols, asserts **set-equality** (count equal + multiset-equal, order-
  insensitive) of `trade_date >= DATE '2022-06-01'` rows. PASS = backfill added rows <2022-06-01
  and changed none ≥2022-06-01.
- **Note:** the `check_operation_succeeded` "success-authoritative / outcome-optional" block that
  appears in the C8 diff is the PRE-EXISTING uncommitted M2-era S2 fix (spec §5 "S2 fix"), NOT a
  Gate-1 change — it was already in the working tree before dispatch.

## Verification (all via verify-run, fresh transcripts in `verify/`)

- `gate1_backfill_compile` — py_compile both .py files → COMPILE_OK, exit=0
- `gate1_backfill_diffstat` — 4 files only (109+/21-)
- `gate1_backfill_diff` / `gate1_backfill_diff_c8` — full diff = C1–C8 only
- `gate1_backfill_grep_dates` — C2/C3/C4 @ 48/70/99 (3 hits); C1 @ 14; C5+C6 @ 32-34/66-69; C7 @ 53
- `gate1_backfill_grep_c8` — C8 identifiers present
- `gate1_backfill_grep_negative` — KA_M2_01 frozen values (0.4325…/0.1639…) still present; old 2022
  dates appear ONLY in frozen KA comments/asserts (lines 21-25, 222-228), NOT in WARMUP dict/header

## Second-opinion review (coder3.8 seat) — PASS-WITH-FIXES (dispatch `ses_fb1ca0919ffetWV3NgMqLpC3cN`)

Independent EXPLORE review by the qwen38-delegate (second engine, different model — author/reviewer
separation). Verdict: **Gate-1 C1–C8 CORRECT and COMPLETE** (all 8 PRESENT-EXACT with file:line;
frozen KAs untouched; old dates confined to KA asserts; 5 read-only commands pass; scoped diff =
C1–C8 only). **Gate-2 design SOUND, one defect — the carrier filename.** Two engines (mine + the
reviewer's probe) independently hit the same finding:

- **F1 (FIXED in spec §4):** the carrier file MUST be named **`warehouse.duckdb`**, not
  `ivw_backfill_m1.duckdb`. DuckDB names a file DB's catalog after the filename stem; the M2 test
  reads `FROM warehouse.warehouse.iv_weekly_state_daily`, which only resolves when the catalog is
  `warehouse`. **F2 (found at Gate-2 execution, FIXED in spec §4):** the spine object must be a
  **materialized TABLE, not a view** — the M1 body creates a session-scoped
  `CREATE OR REPLACE TEMP TABLE _iv_weekly_state_pool`, so a view over the body breaks in the KASA's
  separate read connection. Sequence: `CREATE SCHEMA IF NOT EXISTS warehouse;` then
  `CREATE TABLE warehouse.warehouse.iv_weekly_state_daily AS <re-derived spine>` (body run via the
  M1 KASA's `_strip_ddl`/`_substitute` harness, @start_ds='2021-05-13', @end_ds=pool frontier). The
  M2-absent → kernel re-derivation fallback is confirmed working (materialized-M2 read fails cleanly
  → `_m2()` try/except → `_COMPUTE(m1)`).

## Gate-2 — DONE (all 4 verification events PASS, verify-run transcripts)

Carrier built by qwen-coder (dispatch `ses_fb046f9b5ffe5T3e2qUkqIHRU2`), independently verified:

| Event | Result | Transcript |
|---|---|---|
| carrier check | catalog=`warehouse`; 3,990 rows / 1,330 days; min 2021-05-13, max 2026-08-28; 1 table (BASE TABLE), no percentile object; 11 cols in order; 0 dup keys; 0 days≠3 | `verify/gate2_carrier_check.20260829T225539Z.txt` |
| M2 KASA vs carrier | **PASS** (mode=sqlmesh-context) — frozen monthly KA exact, re-pinned warm-up map matches §3, KA_M2_06 NULLs hold | `verify/gate2_m2_kasa_carrier.20260829T225722Z.txt` |
| M1 KASA regression guard | **PASS** (prod virtual layer, old-window pins) | `verify/gate2_m1_kasa_guard.20260829T225800Z.txt` |
| idempotency carrier≥2022-06-01 vs prod | **PASS** (3,192 = 3,192, set-equal, all 11 cols) | `verify/gate2_idempotency_carrier_vs_prod.20260829T225828Z.txt` |

**Trap caught (record for future sessions):** `python3 tests/test_warehouse_iv_weekly_state_kasa.py`
exits 0 **without running anything** — that test file has NO `__main__` block (the M2 percentile
test DOES). The first "M1 KASA PASS" (…T225732Z) was a no-op; the real run imports the module by
file path and calls `test_iv_weekly_state_known_answers()`. Never trust exit 0 on that file without
the explicit call.

**Frontier note (§7.2):** §3's 3,987/1,329 spine count was measured at pool frontier 2026-08-27;
the pool is live (now 2026-08-28 → 3,990/1,330), so the spine row count is NOT a frozen acceptance
value — the M2 KASA pass is authoritative (anchored to window start 2021-05-13 + mid-window
2025-01-06, not the frontier).

## Next (Gate-3)

Single scoped prod `plan prod` `[nyse_calendar, iv_weekly_state_daily, iv_weekly_percentile]`
(single-use token). BEFORE the write: capture `verify/<gate3_dir>/00_m1_row_baseline.parquet`
(3,192 rows ≥2022-06-01, all 11 cols, read-only duckdb COPY) + metadata `--capture-baseline`.
After: `post_write_verify.py --model warehouse.iv_weekly_state_daily --expect-changed
warehouse.nyse_calendar,warehouse.iv_weekly_percentile --row-baseline 00_m1_row_baseline.parquet`
(SNAPSHOT_DELTA_CLEAN = exactly those 3 changed; ROW_COUNT 3,990 at current frontier — re-measure
at write time; ROW_IDEMPOTENCY set-equal). Final KASA run with no IVW_M1_DB override (prod M1,
prod M2 materialized — the test's default path).

## Standing rule

Executor non-zero exit ⇒ STOP and report, no out-of-band re-run. No prod write at Gate-1.
