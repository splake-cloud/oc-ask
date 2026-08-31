# 2026-08-30 — Stale-warehouse incident: forensics + staged recovery plan (5-deliverable scope executed)

## What was built/decided
PM overrode the earlier "hand to the SQLMesh agent, NOT this seat" scope and dispatched the
5-deliverable stale-warehouse incident to **this seat** to execute. Executed all 5 (investigation
+ planning only; **no shadow re-enable, no frontier recovery executed** — both stay PM-gated).
Deliverable: `studies/iv_weekly_substrate/receipts/2026-08-30_stale_warehouse_incident_forensics_and_recovery_plan.md`.

## Key facts settled (with paths)
- **D1 — the 00:20:50 "mystery write" is explained.** The full journal 2026-08-27 00:20:40→00:21:10
  shows **only `es_live_ingest`** (PIDs 172328/172391) flushing ES 1-min bars + kernel UFW blocks —
  **no sqlmesh/warehouse/duckdb process**. The `sqlmesh_2026_08_27_00_20_48.log` the 2026-08-27 card
  cited **no longer exists** (rotated); it was a 2-sec connect-only run that triggered a DuckDB WAL
  checkpoint (updated the DB file mtime to 00:20:50) with no logical write. **The actual row loss is
  the 22:35:23 restate** (mirror-root log `sqlmesh_2026_08_26_22_35_23.log`): a real
  `DELETE FROM ...__1230283500 WHERE trade_date BETWEEN 2022-06-01 AND 2026-08-24` + `INSERT`, then
  `Promoting/Finalizing environment 'prod'`. **This CONTRADICTS the 2026-08-27 card's "22:35 restate
  was a NO-OP" claim** — the restate mutated the old physical table. Row loss confirmed live:
  `__1230283500` = 1,930,133 rows (max 08-17) vs `__1103730983` = 1,938,281 (max 08-21).
- **The "mirror root" `/data/warehouse/warehouse/` is NOT a rogue project.** It is
  `shadow_run._setup_ctx`'s ephemeral working dir: `shutil.rmtree(PROJECT)` + `copytree(R.WAREHOUSE,
  PROJECT)` each run, `sqlmesh.yml` rewritten to point at the same prod DB (shadow_run.py:55-60).
  Both roots share `/data/warehouse/warehouse.duckdb` (both `sqlmesh.yml` line 10). No cron/systemd
  trigger for it. Its 08-27 21:40 logs are 2-sec connect-only runs.
- **D2 — advance path is structurally sound but NOT safe to re-enable yet.** `ctx.run()` incremental
  + reconcile (last 10 days) → parity ledger; last full run (08-26 23:30) was `ok, 0 unexplained,
  all_ok=True`. Safe to re-enable **only after** (a) the state/bytes mismatch is resolved and
  (b) a preflight confirms no concurrent writer. Keep `--skip-shadow` through recovery; re-enable as
  the **last** gated step.
- **D3 — real staleness (state `end_ts` is EXCLUSIVE, so 1-day gaps are normal EOD lag, NOT stale):**
  - `breadth_daily` (FULL): state 08-26, **physical 2026-04-10 (138 d)** — deep stale.
  - `weekly_vix_study` (FULL): state 08-25, **physical 2026-04-10 (137 d)** — deep stale.
  - `iron_fly_weekly_substrate_v2` (INCR, daily point-in-time substrate for a weekly strategy): state 08-26,
    **physical 08-21 (5 missing trading days)** — prod version `__1103730983` false-complete 08-24..08-25 +
    frontier gap 08-26..08-28. (The 22:35 restate row-loss was on the *old* version `__1230283500`, a different table.)
  - ~12 daily models: physical 08-25, missing frontier days **08-26, 08-27, 08-28** (pool is at 08-28).
  - `nyse_calendar` physical 2026-12-31 = forward-filled, not stale.
  - `warehouse.duckdb` mtime = 2026-08-30 14:56:12; several `_intervals` rows carry `created_ts`
    14:56:12 → state DB rewritten/compacted then (separate event).
- **D4 — staged recovery plan (PM-gated, NOT executed):** Stage 0 preflight (read-only: confirm
  `--skip-shadow` still set, snapshot 26.8 GB state DB + sha256, capture baseline inventory, check
   source freshness for the deep-stale models) → Stage 1 re-derive breadth/weekly_vix (FULL, scoped,
   BLOCKED on source refresh) → Stage 2 iron_fly_v2: scoped restate 08-24..08-25 (false-complete) +
   separately-gated advance 08-26..08-28 (INCR) → Stage 3 advance daily models to 08-28 → Stage 4
   conditional janitor (dry-run first) → Stage 5 remove `--skip-shadow` (the withheld PM-gated mutation) + observe K
  clean runs. Post-recovery proofs: D3 re-run all at frontier, K× 0-unexplained parity, KASA, prod
  sha256 invariant, retain Stage-0 checkpoint.
- **D5 — remove Option B as the final close-out step, after Stage 5's K clean runs.** Its gate
   (`_shadow_skipped AND _blocking_steps_ok`, daily_eod_build.py:618) makes it run **only** under
   `--skip-shadow`; once the advance is re-enabled, `Context.run()` owns the janitor
   (context.py:804-805) → no double-run. It is a temporary bridge for the `--skip-shadow` era.

## Finishing review (qwen-coder, independent, EXPLORE) — APPROVE-WITH-FIXES, fixes applied
Dispatched as a chunked EXPLORE mission (one chunk per deliverable + scope/method + consistency).
Verdict: substantively correct, plan sound. Adjudicated its findings against on-disk evidence
before applying any fix (author ≠ reviewer):
- **Applied (verified):** context.py janitor call is 804-805 not 806-807; no-op claim is card
  line 21 (my 38/49 was the 00:20:50 claim — disambiguated); `plan` alone doesn't mutate, the
  house pattern is `plan prod --auto-apply --no-prompts` via guarded executor (Stage 1/3 +
  principle clarified); K defined = 5 (one trading week, spans a Monday iron_fly entry);
  rollback limitation noted (Stage-0 checkpoint reverts to original staleness, not a fix);
  Stage 4 orphan set enumerated (incl. 3 retired v1 iron_fly versions); post-recovery proof
  1a added (deep-stale models must extend to *source* frontier, else escalate); D3
  `intraday_features_*` provenance corrected (they ARE warehouse SQLMesh models in the
  reconcile TABLES registry, advanced 08-26 23:30).
- **Rejected (reviewer error):** FINDING #6 claimed breadth_daily's source is
  `{MACRO}/breadth_daily.parquet` — that is the *reconcile baseline* (reconcile.py:84); the
  *model* source a re-derive reads is the firstrate zips (`breadth_daily.py:24
  DEFAULT_FIRSTRATE="/data/firstrate"`). Added a clarifying note distinguishing the two.
- **No fix (reviewer self-corrected):** C3.3 weekly_vix_study state_end 08-25 — deliverable was
  already correct.

## Verification (all via `verify-run`, deposited under `verify/`)
- `stale_wh_d3_inventory.20260830T193508Z.txt` — full state-vs-physical table (exit 0).
- `stale_wh_d1_journal_002050.20260830T193513Z.txt` — 00:20:50 journal window = es_live_ingest only (exit 0).
- `stale_wh_d1_rowloss_proof.20260830T193519Z.txt` — restate log DELETE/INSERT/Promoting/Finalizing (exit 0).
- `stale_wh_d1_rowcounts.20260830T193519Z.txt` — `__1230283500` 1930133/08-17 vs `__1103730983` 1938281/08-21 (exit 0).

## Stage 0 — EXECUTED (2026-08-31, per PM authorization; read-only, all guards honored)
- **Guard 1 (no writer):** `pgrep` → only `sqlmesh-subagent-watchdog.sh` (opencode-subagent
  memory-kill loop, no DB write ops). EOD `inactive/dead`, next fire 23h. **Quiescence proven:**
  `lsof` empty + `/proc/*/fd` scan no holder + no `.wal`/`.tmp` + empty `duckdb_temp/`.
- **Guard 2 (space):** 1.3T free on `/` (snapshot target), 2.4T on `/data`.
- **Guard 3 (no SQLMesh init on live DB):** all inspection via `duckdb.connect(read_only=True)`.
- **Guard 4 (snapshot while quiescent, inspect copy):** copied to
  `/tmp/opencode/wh_recovery_20260830/warehouse.duckdb` (16s); **sha256 identical** live vs copy
  `cb5704ab9087b3d9b1d2877842d78228b7ddbfb03ecb0a7ba4813c595f143bf1`; copy opens read-only
  (34 tables, prod env, 27 snapshots). Deeper inspection ran against the copy.
- **No mutations** (no plan apply/restate/backfill/state-repair/shadow-re-enable/janitor/source-refresh).
- Evidence: `verify/stage0_quiescence.*.txt`, `verify/stage0_snapshot_sha.*.txt`,
  `verify/stage0_recovery_matrix.*.txt`.

### Source-freshness diagnosis (the ruling's trigger) — BOTH deep-stale sources STALE at 2026-04-10
- `breadth_daily` ← firrate `index_full_1min*.zip` (`/data/firstrate`): SPX_full_1min **content
  max 2026-04-10** (4597 days; zip mtime 2026-04-11).
- `weekly_vix_study` ← `/data/parquet/vix_daily/vix_daily.parquet`: **max date 2026-04-10** (4602 rows).
- Both models' physical max (04-10) == source frontier → the warehouse is NOT behind the source;
  **the source stopped at 04-10**. Per PM ruling: **do NOT re-derive from stale inputs**; the two
  models are **BLOCKED** on a separately-gated **source-refresh plan** (added to deliverable).
  After refresh, Stage 0 frontier checks must be repeated before Stage 1 is authorized.

### Recovery matrix (key rows; full table in deliverable)
- **breadth_daily / weekly_vix_study** (FULL): source STALE 04-10 → **SOURCE REFRESH** (gated) then re-derive.
- **iron_fly_v2** (INCR; **daily point-in-time substrate for a weekly strategy**, NOT weekly-frequency —
  verified 896 distinct trading days, 5/week contiguous): state claims complete through 08-25, physical
  max 08-21 → **08-24..08-25 FALSE-COMPLETE** (state claims done, bytes absent; 08-22/08-23 are Sat/Sun;
  normal advance won't revisit) + 08-26..08-28 genuine frontier gap = **5 missing trading days**. Mechanism =
  **scoped `--restate-model` of only 08-24..08-25** (re-runs current def, not the 22:35 full-history
  stale-def restate) + separately-gated advance 08-26..08-28. Same prod version `__1103730983`.
  **Origin (3 tiers, PM-confirmed wording):** PROVEN = promoted table ends 08-21 while interval state
  claims through 08-25; STRONG INFERENCE = economic-patch promotion carried interval bookkeeping past the
  materialized backfill frontier; NOT PROVEN = the exact promotion command/log event.
  **Sharpened 5-step sequence (each separately PM-gated):** (1) keep `--skip-shadow`; (2) scoped restate
  08-24..08-25 with current def; (3) prove those 2 dates exist + reconcile rows/keys/strategy-states;
  (4) separately-gated advance through 08-28; (5) prove 5-session continuity 08-24..08-28 + verify other
  daily models reached 08-28 → only then evaluate restoring the scheduled advance.
- **~12 daily models** (FULL/INCR): state consistent (08-26), physical 08-25 → only genuine
  frontier gap 08-26..08-28 → ordinary **advance** suffices.
- Current (0 gap): es_regime, es_tpo_profile, gap_magnitude_daily, intraday_features_*, rv_daily,
  single_print_gaps_v1, sr_levels_v2, tpo_nodes_v1. nyse_calendar forward-filled (not stale).

### PM ruling outcomes applied (2026-08-31)
- **Forensic conclusion ACCEPTED:** no unexplained logical write at 00:20:48–50 (WAL checkpoint);
  damaging op = 22:35 restate. **2026-08-27 card "no-op" conclusion marked SUPERSEDED** (banner +
  inline correction, original preserved verbatim, linked to this forensic correction).
- **Rotated connect-only log NOT pursued further.**
- **Durable invocation auditing APPROVED as a design task (not implementation):** cover CLI +
  Python-context entry points; record PID/PPID, user, cgroup/service, command/caller, project path,
  DB path, environment, timestamps, exit status, full logs — no secrets.
- **Stage 4 janitor now CONDITIONAL** on a fresh eligibility simulation (`janitor --dry-run`);
  Option B may have already cleaned everything eligible → stage may be a no-op.
- **K = 3** consecutive successful scheduled EOD runs, each with 4 proofs: frontier, reference
  (0 unexplained), physical-table (no churn), writer-attribution (journal shows EOD shadow_run,
  no unexplained writer).
- **`--skip-shadow` and Option B stay in place.** No recovery mutation authorized by the ruling.

## Open / next (PM decisions)
1. **Stages 1-5 + source-refresh plan remain PM-gated** — no recovery mutation authorized yet.
2. **Source-refresh plan** (separately gated): refresh firrate SPX zip + vix_daily.parquet past
   04-10, then re-run Stage 0 frontier checks before authorizing Stage 1.
3. **Durable invocation auditing** — design task approved; implementation not yet authorized.
4. Snapshot retained at `/tmp/opencode/wh_recovery_20260830/warehouse.duckdb` (rollback point).

## Traps
- State `end_ts` is **exclusive** — do not report the daily models' 1-day gap as staleness; that is
  normal EOD lag (build trade_date = previous day). Real gaps: breadth/weekly_vix (137-138 d), iron_fly_v2 (5 d).
- The "mirror root" is `shadow_run`'s ephemeral working dir, NOT a second writer.
- Console "Deleted object" lines are NOT the authoritative drop set (janitor trap) — physical diff vs baseline JSON is.
- `sqlmesh -p warehouse status` does not exist; use `check_intervals` + direct `_intervals`/physical queries.
- `verify-run <label> <prog> <args...>` takes program + args as separate argv (a single quoted string → exit 127).
- The `warehouse.duckdb?mode=READ_ONLY` file (12288 B, Aug 27 10:28) is a **separate** incident (malformed
  connection string created a stray 12 KB DuckDB file), not part of this one.
