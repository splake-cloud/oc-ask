# Iron fly substrate v2 — 6-cell parameterized build (post-seal pending)

**Date:** 2026-08-25 · **Seat:** oc-ask · **Topic:** `iron_fly_weekly_substrate_v2` build, prod registration, post-seal restatement

Companion to `2026-08-25_iron_fly_substrate_rag_disambiguation.md` (the RAG fix that motivated the rebuild). This card covers the v2 build itself.

## Design (PM-locked)

- One SQLMesh model, one persistent table, **six parameter cells**:
  `body_grid ∈ {5,25}` × `wing_width ∈ {75,100,120}` (W = per-wing; total = 2W).
- `body_strike = FLOOR((spot + body_grid/2.0)/body_grid)*body_grid`; wings = body ± wing_width.
- `body_grid`/`wing_width` are first-class output columns; `entry_spread_key` encodes
  `entry_date_snap_<grid(3)><width(4)>_<body_strike $0.50>` (collision-proof across both dims).
- `valuation_legs` GROUP BY + all 4 `fly_enriched` windows partition by
  `(entry_trade_date, body_grid, wing_width)` (cell isolation — the trap a presence-check misses).
- Pool scanned **once** (materialized temp table), 6 cells CROSS JOIN `params` CTE.
- New name `iron_fly_weekly_substrate_v2` (width is a column, not in the name; `_v2` matches
  `tpo_nodes_v1`/`single_print_gaps_v1` convention). v1 stays authoritative until v2 passes
  full historical verification.

## Data QA done (before build; all via direct duckdb CLI)

- Grid: 3.13B rows, only 7,277 (0.0002%) strikes off the 5-pt grid (junk far-OTM, untradable).
- 187 in-scope weeks; all 6 cells populated (per-cell quoteable weeks 170–179; 75W>100W>120W
  drop = far strikes occasionally missing in early history, not a bug).
- OTM quote quality month-by-month (51 months, `/tmp/opencode/otm_quality.csv`): nulls/NaN ~0;
  real cost = zero-bid, worst ~3.5% (far OTM calls @120W). Calls decay ~2–3× faster than puts OTM.
- IV quality (`/tmp/opencode/otm_iv_quality.csv`): 99.75–99.97% valid in all 6 wing bands.
  **No imputation needed anywhere.**

## Build state (2026-08-25 ~19:15 UTC)

- Model: `warehouse/models/iron_fly_weekly_substrate_v2.sql` (378 lines, untracked). Read-verified
  line-by-line; one-week repro = 10,962 rows, all 6 cells, correct PK keys.
- verify-runs deposited: `v2-plan-dryrun.*`, `v2-structural-assert.*` (PASS), `v1-untouched.*`,
  `v2-prod-apply.*` (FAILED — see race), `v2-prod-apply-retry1.*` (FAILED), `v2-prod-register-empty.*` (SUCCESS).
- **v2 is REGISTERED in prod env** via `plan prod --empty-backfill --auto-apply --no-prompts`
  (PM-directed; token minted in-session). Interval marked complete-with-0-rows, so
  `check_intervals` says "Complete" = **registration state, NOT materialization**.
  Historical fill requires an explicit restatement — the 03:05 daily run will NOT do it.
- v1 (`iron_fly_weekly_substrate`): untouched, 323,226 rows, 3 snapshots in prod.

## The pool race (why full-range backfill kept failing)

- Error `don't know what type:` (DuckDB, compile-time) was **non-deterministic**: same query
  passing/failing across runs. Root cause: `read_parquet(glob, union_by_name=true)` opens ALL
  1523 files for schema union, including `2026-08-25.parquet` which `spx_live_ingest`
  (PID 2720/2723) rewrites in ~640KB bursts every ~50s during market hours (verified host vantage,
  netns 4026531833, seccomp 0). Row filters do NOT stop the schema read.
- Model is correct — every failure was I/O, not SQL. 5 gated retries failed because the 12s
  stability window << 150s scan; scan always crosses a write burst.
- PM ruling: **file-state trigger, not clock.** No retries. One post-seal restatement.

## Config conflict (fixed ~19:15 UTC)

- `warehouse/config.py` (untracked, created 19:01 for "programmatic access") + `sqlmesh.yml`
  coexisted → `ConfigError: Multiple configuration files found` on BOTH load paths (Python
  Context AND CLI). Blocked the post-seal watcher.
- Resolution: **deleted `config.py`** (git clean). Reasons: nothing imports it (auto-discovery
  only); `scripts/spec_intake_check.py:34` hardcodes `SQLMESH_YML = ".../warehouse/sqlmesh.yml"`
  (Gate 0 would break if the YAML were renamed); `Context(paths=[...])` loads the YAML fine
  (proven: 26 models, `infer_python_dependencies: True`).
- Dependencies: no loss. Both configs were semantically identical; Python models
  (`iv_percentile_daily.py`, `fly_paths.py`, …) pin runtime deps in `requirements-sqlmesh.lock`
  (separate, untouched); YAML preserves `infer_python_dependencies: true`.
- `sqlmesh.yml.bak`: left in place — gitignored by design (`.gitignore:26 warehouse/*.bak*`),
  not a config filename, harmless.
- Both load paths verified restored after removal.

## Post-seal trigger (running)

- `/tmp/opencode/v2_postseal_trigger.py` (PID 549096, launched ~18:32 UTC), status file
  `/tmp/opencode/v2_trigger_status.json`, log `/tmp/opencode/v2_postseal_trigger.log`.
- GATE (file-state, not clock): `2026-08-25.parquet` (size, mtime, inode) unchanged ≥180s AND
  zero write-open handles (via /proc/*/fdinfo flags, not process name).
- On seal → exactly ONE attempt: (1) seal evidence → (2) fresh PM token scoped to the exact
  restatement argv (hash via executor's own `compute_normalized_hash`) → (3) guarded
  `plan prod --restate-model warehouse.iron_fly_weekly_substrate_v2 --auto-apply --no-prompts` →
  (4) require success (else FAILED, stop, no retry) → (5) check_intervals → (6) 6-cell coverage →
  (7) PK uniqueness → (8) row/date/expiry coverage. Steps 5–8 deposit via verify-run
  (`v2-postseal-*`). 5h hard stop → BLOCKED.
- **Transition invariant:** v1 remains authoritative until v2 has full historical coverage,
  all six cells, zero PK dups, expected row/date coverage. THEN: v1 reference-parquet export →
  v1 model retirement (delete file + commit + `plan prod` → SQLMesh plans the drop) → RAG card
  repoint (`iron_fly_vs_fly_disambiguation` currently names the wrong substrate).

## Reconciliation (PASSED, ~20:42 UTC)

- Independent recompute of **5 deterministic weeks × 6 cells = 54,678 rows** from canonical
  parquet (NO v2 read): expiries 2022-06-10 (first), 2022-06-17 (early interior), 2022-07-29
  (collision: entry 2022-07-25, spot 3974.72 → body 3975 on BOTH grids), 2024-06-14 (middle),
  2026-08-21 (recent). Compared row-for-row by 19-col EXCEPT both directions.
- **Result: 0 / 0** (expected_minus_actual, actual_minus_expected). All 19 cols match:
  keys, strikes, spot, entry_ts, 4 traded legs (put_wing_bid, put_body_bid, call_body_ask,
  call_wing_bid), fly_value_bidask, and the 3 derived mids (fly_value_mid, entry_debit_mid,
  exit_credit_mid).
- Deposit: `/data/agentic_trading/verify/v2-recon-19col-5wk-EXCEPT-0of0.20260825T204211Z.txt` (exit=0).
- The only bug found was in MY VERIFIER, not the model: line 72 put-wing mid term was
  `(put_wing_bid + call_wing_ask)/2.0` (wrong operand) → fixed to `(put_wing_bid + put_wing_ask)/2.0`.
  Model (`iron_fly_weekly_substrate_v2.sql:223`) was always correct.

## KASA suite (existing, needs adaptation)

- `tests/test_warehouse_iron_fly_weekly_substrate_equivalence.py` — v1's 15-KA KASA suite
  (standalone `python3` runner, not pytest; connects to `/data/warehouse/warehouse.duckdb`).
  Spec tables: `builds/iron_fly_weekly_substrate/build_spec_iron_fly_weekly_substrate.md:217-241`
  (KA_IF_01..15).
- Reusable as-is (point at _v2): KA_03 (189 weeks), KA_04 (quoteable), KA_05 (PK uniqueness),
  KA_11 (incomplete bars), KA_13 (schema, now 48 cols), KA_14 (PK NOT NULL), KA_15 (types).
- Need parameterization per cell: KA_01 (row count ~6× but not exact), KA_02 (body deviation
  ±2.5 for grid-5 / ±12.5 for grid-25), KA_06/KA_12 (debit/MTM bounds widen with wing width;
  ±50 was for 25W), KA_07 (IV — passes easily, far wings are 99.75%+).
- NEW KAs needed: 6-cell coverage (exactly 6 pairs, n_weeks ≥170 each), wing algebra invariant
  (lower = body−W, upper = body+W), dimension domain (grid ∈ {5,25}, W ∈ {75,100,120}).
- **BUILT + PASSED 14/14 (~20:47 UTC):** `tests/test_warehouse_iron_fly_weekly_substrate_v2_sixcell.py`
  (476 lines, standalone `python3` runner, read_only duckdb, physical table
  `sqlmesh__warehouse.warehouse__iron_fly_weekly_substrate_v2__1230283500`, 48 cols).
  Deposit: `/data/agentic_trading/verify/v2-kasa-sixcell-14of14.20260825T204751Z.txt` (exit=0).
  Tests: schema(48), cell_domain(6), cell_week_coverage(181×6), funnel_row_count(1,939,361±1k),
  key_and_grain(0 null/0 dup), body_strike(grid dev ≤grid/2, 0 off-grid), wing_algebra(0 viol),
  entry_exit_timestamps, dte(=4), quoteable_iv(0.9786/0.9786 @entry), incomplete_bars(≤30),
  ranges(debit[-106.75,-34.20], fly[-179,3610.05]), date_bounds, source_accessibility.
  v1's 15-KA 25W-only bands do NOT transfer (correct): quoteable 80.65% all-rows / 97.86% @entry,
  IV 98.9% all-rows / 97.86% @entry, incomplete bars 30 (not ≤11), debit/MTM far wider than ±50.

## v2 FULLY VERIFIED (2026-08-25)

Reconciliation 0/0 + 14/14 KASA + 8 structural checks all PASS. The **transition invariant is
satisfied**. Transition (all PM-authorized, 2026-08-25) is now COMPLETE end-to-end: v2 committed
`14c7e148`, v1 reference parquet exported (sha256 recorded), v1 model file retired `167e9e0a`, the
prod plan to drop v1 from the environment applied via the guarded executor (review-first, zero
physical changes), and the RAG card `iron_fly_vs_fly_disambiguation` (+3 dependent clauses) repointed
to v2, live-served (rank #1), and committed `98fc1580`. **The v1→v2 transition is complete
end-to-end; nothing remains open.**

## Transition steps (PM-authorized, executed 2026-08-25)

1. ~~Watcher fires / KASA / reconciliation~~ — DONE (see Reconciliation + KASA sections).
2. **v2 committed as its OWN commit — DONE `14c7e148`** (PM-directed, commit-first-before-v1):
   `sqlmesh: add verified six-cell iron fly substrate v2` — exactly 4 files (888 insertions):
   `warehouse/models/iron_fly_weekly_substrate_v2.sql`,
   `tests/test_warehouse_iron_fly_weekly_substrate_v2_sixcell.py`,
   `verify/v2-recon-19col-5wk-EXCEPT-0of0.20260825T204211Z.txt`,
   `verify/v2-kasa-sixcell-14of14.20260825T204751Z.txt`. v1 model untouched.
3. **v1 reference export — DONE** (PM-specified dedicated reference archive, NOT the SQLMesh
   backup archive, NOT /var/tmp):
   `/data/warehouse/reference_archive/iron_fly_weekly_substrate/iron_fly_weekly_substrate_v1_superseded_20260825.parquet`
   (323,226 rows × 46 cols; verified by full-row EXCEPT vs source = **0/0** both directions;
   sha256 `38d6cf96547cab4426e0d2a459baeabbf26e799ed1e19cd06dbdf9ed2066555c`) +
   adjacent `iron_fly_weekly_substrate_v1_superseded_20260825.meta.json` (source_relation, rows,
   status=superseded, reason, replacement=_v2, exported_at, parquet_sha256, verification block,
   provenance_note). Kept for RAG-disambiguation provenance (the wrong-25W history).

## Transition execution log (ALL DONE — complete end-to-end)

1. ~~Retire v1 model file~~ — **DONE `167e9e0a`** `sqlmesh: retire superseded iron fly substrate v1`
   (1 file, 334 deletions, committed SEPARATELY after the v2 commit per PM ordering). Precondition
   verified first: reference parquet exists + sha256 recorded. `sqlmesh.yml` has NO explicit ref to
   the v1 path (auto-discovery from `warehouse/models/`) → deleting is clean; the other file-path
   hits are historical docs/specs/scripts, not load-time deps. Only v2 remains as an iron-fly model.
   ⚠ the v1 PHYSICAL tables remain on disk as the safety net (see below).
2. **Prod plan to retire v1 — DONE (PM-authorized, guarded path, ~21:14 UTC).** Review-first
   (read-only `sqlmesh diff prod` = EXACTLY "Removed Models: warehouse.iron_fly_weekly_substrate
   (Breaking)", nothing else) → minted fresh PM token `pm_prod_retire_iron_fly_v1_20260825`
   (command_hash `bcbc7f0d…e04d` via executor's `compute_normalized_hash`, env=prod, 6h) bound to
   argv `plan prod --auto-apply --no-prompts` → applied via
   `python3 .guarded_runtime/sqlmesh_executor.py --token <path> -- plan prod --auto-apply --no-prompts`
   (exit 0). Result: SQLMesh removed the v1 model from the prod ENVIRONMENT's virtual layer;
   **"SKIP: No physical layer updates to perform" / "SKIP: No model batches to execute"** = ZERO
   physical changes (no v2 rebuild, no unrelated destructive op). Post-apply: `sqlmesh diff prod`
   = "No changes to plan: project files match the prod environment"; token in consumed_tokens
   (single-use honored).
   Evidence: `verify/v1-retire-prod-plan-review.20260825T211435Z.txt`,
   `verify/v1-retire-prod-plan-applied.20260825T211438Z.txt`.
   Data state: v2 = 1,939,361 rows (untouched); v1 PHYSICAL tables still on disk (4 snapshot tables,
   e.g. `__2879869426` = 323,226 rows) = safety net; 31 model physical tables total, all present.
3. **Repoint RAG card — DONE (~21:40 UTC, PM-authorized; followed docs/RAG.md Checklist H).**
   Source of truth = `scripts/rag_verifier/build_contracts.py` (curated `data_contracts` well, 86
   cards). Repointed the canon card `iron_fly_vs_fly_disambiguation` (text: iron fly = body nearest
   `body_grid`-multiple, wings `body ± W`; AUTHORITATIVE substrate = `iron_fly_weekly_substrate_v2`
   6-cell body_grid∈{5,25}×wing_width∈{75,100,120}; fixed nearest-5/±100 = ONE of the six cells, not
   the rule; v1 SUPERSEDED + RETIRED + history in reference_archive; triggers/evidence updated) AND
   3 dependent scope clauses that deferred to it (spx_long_put_fly_debit, spx_cash_centered_option_
   strikes, spx_20w_fly_wing_spacing) — those still baked the old fixed spec and would have
   contradicted the new canon. Process: edit builder → scan-stage --groups data_contracts → verify
   staged JSONL before seeding → seed-pending --root all (full 8B + small 0.6B, 86 rows each, backed
   up) → status live both roots → keyed fetch both roots (asserted v2/RETIRED present, old spec
   absent) → **live service returns repointed card RANK #1** (score 6.312). Deposit:
   `verify/rag-repoint-ironfly-v2-both-roots.*` (RESULT PASS, exit=0). NOTE: live `:8765` serves the
   SMALL root (RAG.md §7.0 prose "full root" is documented drift; /health is authoritative).
   **COMMITTED `98fc1580`** `data_contracts: repoint iron-fly disambiguation card to six-cell v2
   substrate` (1 file; the two lance indexes + staged JSONL are on-disk data, not tracked).
4. v1 build spec's KAs reference the wrong (25W) values — superseded by v2 spec values.

## Critical context

- PM token mechanics (this session's path): token JSON in /tmp/opencode (NOT committed, NOT in
  `.sqlmesh_runtime/`), `command_hash` = SHA-256 of normalized argv computed with
  `.guarded_runtime/sqlmesh_executor.py::compute_normalized_hash`, `environment: "prod"`,
  `single_use`. Token consumed ONLY on success (executor line ~315) → safe to re-mint same argv.
  Docs: `docs/SQLMESH_MUTATION_POLICY.md` + `docs/SQLMESH_EXECUTION_MODEL.md` (canonical, v2.0).
- The RAG `sqlmesh_reference` collection is a SKELETON (concept bodies = "N/A"); real content is
  in `docs/sqlmesh_reference/*.yaml` + the sibling `docs/SQLMESH_*.md` policy docs.
- Warehouse prod state = `/data/warehouse/warehouse.duckdb` (data + sqlmesh._* state, gitignored);
  single `prod` env; no automated `sqlmesh run` cron for prod (daily advance is via the
  `wh_daily` token pattern; backup cron 02:00 only).
- Retire path (grounded): delete model file + commit + `plan prod --auto-apply --no-prompts`
  (SQLMesh plans the drop). No `sqlmesh deprecate` exists.
- Sandbox caveat exercised: file-size/process observations for the seal gate are only valid from
  host vantage (this seat IS host: netns 4026531833, seccomp 0).
