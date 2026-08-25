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
- Can only run after the restatement fills the table (currently 0 rows).

## Open / next

1. Watcher fires on seal (expected ~20:00 UTC market close or later). Check
   `/tmp/opencode/v2_trigger_status.json` — expect `SEALED → APPLIED` or `FAILED`/`BLOCKED`.
2. On APPLIED: run the adapted v2 KASA suite (formalize the new KAs), review results with PM.
3. On full verification pass: v1 reference parquet export → retire v1 model → repoint RAG card.
4. v2 model file is still **untracked** in git — commit it (with KASA test) after verification.
5. v1 build spec's KAs reference the wrong (25W) values — superseded by v2 spec values.

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
