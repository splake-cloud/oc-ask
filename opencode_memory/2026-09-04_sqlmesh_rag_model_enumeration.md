# 2026-09-04 — sqlmesh_reference RAG cards: model enumeration de-baked-in (durable fix)

## What was done

Made the SQLMesh model enumeration in the RAG **non-baked-in** so it can no longer rot.
Two cards in `docs/sqlmesh_reference/` carried a hard-coded "25 models" count + full
model lists that had drifted to 32 definitions (19 SQL + 13 Python) without the cards
being updated. Replaced the enumerations with **compute-at-read-time pointers** (option 2,
the durable choice, over just patching the number).

## The finding

- Live model count (measured from `warehouse/models/`): **32 definitions = 19 SQL + 13 Python**.
- Cards said **25** (15 SQL + 11 Python). 7 models missing from the `model_structure`
  card: `es_1min_front`, `es_1min_live`, `nq_1min_live`, `iv_weekly_state_daily` (SQL) +
  `cot_positions`, `short_interest`, `iv_weekly_percentile` (Python).
- "25 models" appeared in 4 cards: `local_architecture/two_project_pattern` +
  `warehouse_timing` (overview, dag_layers, our_usage).
- **Root cause (same class as the fly stale-parquet):** model lists are hand-authored
  `verbatim_text` in the card YAMLs, not computed from the model dir. They drift silently
  every model ship. The `warehouse_health` card already states the rule ("a guide that
  hardcodes counts fails the week someone ships a model") but the architecture/timing
  cards didn't follow it.
- The other local cards (`local_incremental_policy`, `local_modeling_rules`) use model
  names as *examples/templates* ("stg_spx_options uses lookback 3"), not enumerations —
  left alone; they won't rot.

## What changed (2 files, both hand-authored card YAMLs)

- `docs/sqlmesh_reference/local_architecture.yaml`
  - `model_structure` verbatim: 15-SQL/11-Python lists + "(25 models)" → "computed from
    `warehouse/models/` at read time; as of 2026-09-04 there are 32 definitions (19 SQL +
    13 Python); recompute before relying on a number" + a few representative names only.
  - `two_project_pattern` verbatim: "(25 models)" → "one SQLMesh model per table; full
    list + count computed from the directory at read time."
- `docs/sqlmesh_reference/sqlmesh_reference_warehouse_timing.yaml`
  - 4× "25 models" → "every warehouse model (count computed from `warehouse/models/` at
    read time)."
  - The 25-model 4-layer DAG table is now explicitly flagged **"SNAPSHOT 2026-09-04, 25 of
    32 models; recompute the current DAG from `warehouse/models/`"** (in the dag_layers
    definition, the verbatim DAG sentence, and a new key_invariant).

## Verification (both roots, 234 rows each)

- Full root `/data/parquet/verifier_kb/indexes` + small root
  `/data/parquet/verifier_kb_small/indexes`: **`stale "25 models"` cards = 0**,
  **compute-at-read cards = 4** each.
- Manifest: `sqlmesh_reference full=live small=live` (234 rows).
- Live `:8765` `/search` (POST, body field is **`query`** not `q`, must pass
  `collections`) returns the new text; `model_structure` top hit reads "COMPUTED at read
  time … 32 definitions (19 SQL + 13 Python)."

## Mechanism / traps (reusable)

- **Harvester embeds `verbatim_text` verbatim** (`harvest_sqlmesh_reference.py:74-76`);
  `definition` also embedded in the overview chunk. Editing the YAML `verbatim_text` is
  what changes the searchable text.
- **Well fingerprint watches both card YAMLs AND model files**
  (`refresh_planner.py:445-470`), so a model ship OR a card edit restages the well
  automatically. Now that the lists are pointers (not enumerations), they won't go stale
  in the first place.
- **`scan-stage` is CPU-only** (fingerprint + harvester, writes staged JSONL). **`seed-pending`**
  is what writes vectors (needs the embed model). Staging is root-independent (one staged
  corpus); seeding is per-root.
- **Full-root seed is GPU-blocked by design** (needs 28 GB free for the 8B embedder; the
  live `:8765` holds ~76 GB on GPU0). It ran **on CPU** (`--device cpu`, 251 GB RAM free) —
  ~25 min for 1324 chunks, non-disruptive, `:8765` stayed healthy throughout. Small root
  (0.6B, 4 GB floor) seeds fast on GPU.
- **TRAP — `seed.py --recreate` is destructive mid-run:** a first CPU-seed attempt killed
  at the 120 s foreground timeout had already `--recreate`-dropped the full-root
  `sqlmesh_reference` table (0 rows on disk) and left `duckdb_views`/`output_lineage` at 0
  and `table_recipes` partial. The live service still served old vectors from memory, so
  `:8765` looked fine — but the on-disk index was corrupted for 4 collections. The
  completed run rebuilt all 5. **Lesson:** never run a long `--recreate` seed in the
  foreground under the 120 s tool timeout; launch detached (`setsid nohup ... &`) and
  poll, or it can leave a half-recreated index.
- **The 5 full-root collections were all already pending** (the other 4 — data_location,
  table_recipes, duckdb_views, output_lineage — from the earlier fly-data reseed this
  session), so the full seed was needed regardless of the card edit.

## Files

- `docs/sqlmesh_reference/local_architecture.yaml` — edited (model_structure + two_project_pattern)
- `docs/sqlmesh_reference/sqlmesh_reference_warehouse_timing.yaml` — edited (4× count + DAG snapshot flag)
- `scripts/rag_verifier/harvest_sqlmesh_reference.py` — read (verbatim_text embedding, :74-76)
- `scripts/rag_verifier/refresh_planner.py` — read (fingerprint :445-470, seed_pending :892, _seed_one_root :815)
- `docs/sqlmesh_reference/manifest.json` — read (created 2026-08-25, last_updated 2026-08-26, sqlmesh 0.236.x)

## Open / next

- None blocking. The durable fix is live on both roots.
- The 4 other full-root collections were re-seeded as a side effect (they were already
  pending from the fly-data work) — full-root index is now fully consistent
  (data_location 142, table_recipes 198, duckdb_views 296, output_lineage 454,
  sqlmesh_reference 234).
- NOTE: the 7 "missing" models include the ES/NQ 1-min live feeds (PM GO 2026-09-03, see
  2026-09-03_sqlmesh_registration_parity card) and the IV-weekly + COT/short_interest
  export models — all expected, none anomalous.
