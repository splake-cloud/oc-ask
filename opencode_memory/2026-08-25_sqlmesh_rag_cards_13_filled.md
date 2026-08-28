# SQLMesh reference RAG: 13 N/A cards filled, double-reviewed, all fixes landed

**Date:** 2026-08-25 · **Seat:** oc-ask · **Topic:** sqlmesh_reference RAG collection completion + validation

## What was built/decided

Filled all 44 N/A concept sections across 13 sqlmesh_reference RAG cards in
`/data/parquet/verifier_kb/staged/sqlmesh_reference.jsonl` (211 chunks). Excluded from scope
by PM: `local_agent_activation` + `local_agent_guidance` (pilot mode — still have N/A).

Pipeline: (1) qwen-coder filled 13 cards from source files; (2) structural validation
(211/211 key conformance, section order, ID consistency); (3) qwen-coder EXPLORE fact-check
(131 concrete claims: 106 verified, 3 wrong, 22 framework/unverifiable); (4) 3 fixes applied;
(5) **claude-opus-4-7 headless review via `claude_wrapper.py`** found the big ones:
- **Off-by-one body rotation** in `local_modeling_rules` + `local_incremental_policy` (each
  concept's body described the NEXT concept) — 14/16 advertised queries would hit the wrong body
- Misleading `df = context.table(...)` example (returns table-name STRING, not DataFrame)
- Two invented contradictory dev-table naming schemes in `architecture_snapshots`

Verdicts: 4 APPROVE (cli_run, community_late_arriving_data, community_stale_derived_tables,
restatement), 4 APPROVE_WITH_NOTES (fixed directly in oc-ask), 4 REWORK (dispatched to
qwen-coder, then oc-ask applied 3 residual fixes Claude's summary misreported as done:
execution_context body, change_categories body, snapshots agent_queries).

## Key facts settled

- **Live service reads `/data/parquet/verifier_kb_small`** (stale 97-chunk copy, 143 N/A,
  mtime 08-17) while canonical staging is `/data/parquet/verifier_kb/staged/` (all
  `scripts/rag_verifier/*.py` default `VERIFIER_KB_ROOT` there). **New content is NOT live —
  refresh/stage is a PM-gated GPU step.** Next session: stage + reindex when PM says go.
- Empirical physical-layer naming (verified from warehouse.duckdb, 2026-08-25): schemas are
  `warehouse` (VIEWs = virtual layer) + `sqlmesh__warehouse` (BASE TABLEs
  `warehouse__<model>__<snapshot_id>` = physical layer); temp tables
  `__temp_warehouse__<model>__<id>_<hash>`; single 'prod' environment, no dev schemas.
- `iron_fly_weekly_substrate` v1 RETIRED (commit 167e9e0a) — only v2 exists; cards now say v2 only.
- Local dependency graph verified: vol_summary reads atm_iv_daily/rv_daily/iv_percentile_daily
  (NOT stg_spx_options); stg_spx_options → atm_iv_daily, fly_trades.
- No `partitioned_by`, no `forward_only`, no `audits/` dir, no user-defined audits, no
  `resolve_table()` usage anywhere in the warehouse project — cards now say so explicitly.
- `Context(paths=...)` must point at the project dir only; repo root picks up BOTH
  `warehouse/sqlmesh.yml` and `sqlmesh/config.yaml` → "Multiple configuration files found".
  A `warehouse/config.py` now exists (created this session to load the context);
  `sqlmesh.yml.bak` also present.

## Open / next

1. **PM gate: stage + reindex the sqlmesh_reference collection** so the live
   verifier_kb_small index serves the 211-chunk version (currently serves 97-chunk 08-17 copy).
2. RAG card count delta on refresh: sqlmesh_reference 97 → 211 (small root).
3. Pilot cards (local_agent_activation, local_agent_guidance) remain N/A until pilot completes.
4. Minor Claude notes left unaddressed (low value): architecture_plans 3 concepts thin;
   `forward_only_and_restatement` 2-line stub in restatement card.
