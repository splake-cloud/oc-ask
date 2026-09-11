# Gamma `capture_era` + `session_grid_class` semantic correction — receipt (2026-09-11)

One semantic correction to the `gamma_research` view and its consumers, driven by the
verified fact that the UW gamma substrate is **0DTE-only for its entire history** and the
`expiry` column is a **capture-echo artifact**, not a data attribute. The old columns
labeled the data by the wrong field; the new ones key off `trade_date_et` and the actual
slice count. Fully verified; applied to both DuckDB catalogs.

## The correction (semantic, not compatibility-preserving)

In `gamma/research_views.sql` (the sole DDL source of truth for the `gamma_research` /
`gamma_research_active` views):

| old column | new column | how it's defined now |
|---|---|---|
| `expiry_regime` = `CASE expiry='all' THEN 'all_expiry' ELSE '0dte'` | **`capture_era`** = `CASE trade_date_et < DATE '2026-06-30' THEN 'pre_2026_06_30' ELSE 'post_2026_06_30'` | strictly from the trade date. A **VENDOR / DATA-POPULATION boundary** (the 2026-06-30 periscope migration), **NOT an expiry classification**. The feed is 0DTE on both sides. |
| `grid_regime` = hard-coded date cutoffs (`<03-09`→A_36, `<06-10`→B_42, else C_43) | **`session_grid_class`** derived from a new `session_grid` CTE | `count(distinct slice_open_utc) per trade_date_et` → 36→`A_36`, 42→`B_42`, 43→`C_43`, else `ODD_<n>`. |
| `regime_outlier_day` = `(trade_date_et = '2026-06-16')` | **dropped** | the 06-16 "outlier" framing encoded the discredited regime-migration theory. |

No alias retained. `expiry_raw` (the raw `expiry` column) is kept as a passthrough, not as a
label source.

### Inflation proof (required)
The slice count is over the **distinct time coordinate** (`slice_open_utc`), never physical
rows. `bars` has one row per (slice × strike), so duplicate strike/node rows for a slice
collapse to one. Verified on all 186 dates: `distinct(slice_open_utc) == distinct(snapshot_id)`
with **0 mismatches**; rows-per-slice varies 171–445 (strike multiplicity), confirming the
count is invariant to strike/node duplication.

## Pre/post DDL hash
- Pre-apply: `25aeeb73bf559dae5b44f405458b2ddaa20ec10950b38ca342a4263fc7883e8c`
- Post-apply: `098b72880c85a5b4806a87e906e39535afa1343dce04ed5afa28b7e5e9b1076f` (both `research.duckdb.ddl_hash` and `/data/parquet/research_v2.duckdb.ddl_hash`)

## Apply mechanism (no hand-editing of either DuckDB)
`catalog/register_catalog.py` applies 6 SQL sources (incl. `gamma/research_views.sql` +
`gamma/spot_join.sql`) to **both** `research.duckdb` and `/data/parquet/research_v2.duckdb`
in one run — idempotent `create or replace`, auto-backup on DDL-hash change, restore-on-fail.
Single run; both DBs updated.

## Backups (created on apply)
- `/data/agentic_trading/research.duckdb.bak.20260911T175302-consolidate`
- `/data/parquet/research_v2.duckdb.bak.20260911T175303-consolidate`

## Schema + value populations (identical on both DBs)
- `gamma_research` / `gamma_research_active`: 25 columns each; column lists **identical across the two DBs**; the old 3 columns (`expiry_regime`, `grid_regime`, `regime_outlier_day`) **absent**; `capture_era` + `session_grid_class` **present**.
- Full-lake populations (identical both DBs): **1,653,311 rows / 186 dates / 7,538 snapshots**.
  - `session_grid_class`: `C_43=80, A_36=56, B_42=48, ODD_26=1 (2025-12-24), ODD_40=1 (2026-03-31)`.
  - `capture_era` date counts: `pre_2026_06_30=135, post_2026_06_30=51`; **first `post_2026_06_30` = 2026-06-30**.

## Date-level audit + raw→view census reconciliation
186-date audit (one `capture_era` + one `session_grid_class` per date; no date has multiple).
An **independent** census recomputed `count(distinct slice_open_utc)` directly from the
underlying parquet (not through the view) reconciled to the view on **all 186 dates** —
`n_slices`, `session_grid_class`, and `capture_era` all agree.

### Two distinct facts that must NOT be conflated (made explicit)
1. **The first individual C_43 (full-RTH, 43-slice) session is 2026-05-15.** It is a *lone*
   full day.
2. **2026-05-19 begins the uninterrupted/full-grid run** (79 C_43 days through present).
   "First full day" (2026-05-15) ≠ "start of the full-grid era" (2026-05-19). 2026-05-18 is
   the lone non-43 (B_42) day inside that window (its 16:00 is an upstream void).
   The catalog now states this explicitly to prevent the two from being merged again.

## Validator (full report, `gamma/validate_research_views.py`, pin ≤ 2026-07-31)
ALL CHECKS PASSED, EXIT=0. Every check: 1 `1339485` · 2 `6334` · 3 `158` · 4 `647565` ·
5 `pre_2026_06_30`=5345 · 6 `post_2026_06_30`=989 · 7 `0` · 8 `0` · 9 `0` · 10 `(632,584)`
(report) · 11 `{A_36,B_42,C_43,ODD_26,ODD_40}` · 12 5/5 pre-existing views. Checks 1/2/4
constants were **recomputed** (not carried forward) because the 2026-09-03 re-ingest advanced
the pin (1,334,674→1,339,485 rows; 6,315→6,334 snaps; 646,935→647,565 active). (The 30s perf
warning is pre-existing — the lateral spot join is inherently ~47s.)

## Scope (6 implementation files, single commit "Correct gamma capture-era and session-grid semantics")
1. `gamma/research_views.sql` — DDL (the source of truth).
2. `gamma/validate_research_views.py` — checks 1/2/4/5/6/11 re-keyed + recomputed.
3. `analysis/sml_fly_verify/gamma_topology/phase2_uw_topo.py`
4. `analysis/sml_fly_verify/gamma_topology/cohort_map_builder.py`
5. `analysis/sml_fly_verify/gamma_topology/acquisition_scorer.py`
6. `docs/data_catalog.yaml` — `read_via` note (column names + read path), `verified_facts`
   (0DTE-only fact, capture_era, session_grid_class, capture window, partial-days), assertion
   descriptions. **Note:** this file also carried the prior RAG-accuracy rewrite (same
   gamma-domain facts, intermingled on the same lines); it is committed together as the
   documentation counterpart — the RAG *cards* themselves were deleted/reseeded live earlier
   in this thread and are not part of this commit.

The 3 study consumers were updated with **no dual-schema fallback** (old names removed, new
names explicit). All four consumers `py_compile` clean. No additional dependency: the only
other in-tree hits for the old names are intentional "the old X was wrong" doc comments.

## STALE-OUTPUT WARNING (made explicit)
`analysis/sml_fly_verify/gamma_topology/cohort_alignment.parquet` and
`analysis/sml_fly_verify/gamma_topology/acquisition_scores.parquet` each carry a `regime`
column populated from the **old `expiry_regime`** (keyed off the `expiry` echo). They embed
the former labels `all_expiry`/`0dte`. **They are now semantically stale and MUST NOT be
reused without re-deriving the era assignment from `capture_era` (or `trade_date_et`
directly).** On the 18 mixed-echo days (2026-05-15..2026-06-29) the old echo-derived split
and the new strict trade-date `capture_era` can differ (a dated-echo day in that window was
labeled `0dte` before but is `pre_2026_06_30` under the strict rule). `gamma_topology_uw_phase2.parquet`
is NOT affected (its `arm` column holds display names `ALL-EXPIRY`/`0DTE-ONLY`, not former
column values). **The two historical parquets were NOT regenerated or rewritten in this
commit** — per instruction, do not rewrite historical findings.

## Open / next
- The node-materiality findings were removed from the RAG earlier in this thread; a deeper
  re-examination is separate and pending. If it reuses `cohort_alignment.parquet` or
  `acquisition_scores.parquet`, re-derive the era first (see stale-output warning).
