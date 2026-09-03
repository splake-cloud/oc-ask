# 2026-09-03 — spx_15min "dual contract" discovery → verified already-fixed → stale RAG card corrected + reseeded

**Context:** user surfaced a discovery that six catalog/registry systems are fragmented,
with P0 = "`spx_15min` resolves to two different live tables with different keys/columns
depending on access layer." Asked to fix P0 with the constraint "verify it is safe, account
for dependencies, nothing can break."

## Verdict: P0 was ALREADY FIXED — the discovery was built on a stale RAG card
- The dual contract was real and was deliberately resolved **2026-07-27** (commit
  `2f817f43` "resampled views: stop building the three that collide with a canonical
  parquet"). It dropped the `spx_5min/15min/30min` research.duckdb views and made the
  producer write parquet only. **No mutation was needed.**
- The RAG failure-prior card the discovery quoted was measured **2026-07-26** — one day
  BEFORE the drop — and still said "BOTH are live today." That sentence was false by
  2026-07-28. **A RAG hit is a prior, not proof — I re-verified against live state, per
  AGENTS.md RAG-grounding doctrine.**

## Verified live state (read-only, 2026-09-03 ~12:48 UTC, re-checked after "things moved")
- `spx_15min` object count = **0** in all four DBs (research.duckdb, /data/parquet/
  research_v2.duckdb frozen mirror, warehouse.duckdb ×2). Only `spx_1min` + `spx_45min`
  views remain.
- Single live object = catalog parquet `/data/parquet/spx_15min/spx_15min.parquet`
  (121,646 rows, 2008-01-02→2026-09-02). Passes every `data_catalog.yaml` assertion
  (bad_first_open=0, after_1600=0, bad_nominal=0, over_nominal=0; reg=26/half=14).
- `gate_resampled_view_collision.py --expect pass` → **GATE PASS** (5/5).
- **spx_45min was deliberately KEPT** (view-only, the ONLY 45-min access — no parquet
  equivalent). The fix was "three views, not four," enforced by the gate.
- "Things moved" = only the **routine nightly parquet refresh** (mtime 2026-09-02 23:32,
  row counts grew a few sessions). Contract + views unchanged. No git commit in 3 days
  touched the resampled-view/catalog surface.

## The real residual (P4, RAG hygiene): the card's rendered text was misleading
- The card `one_dataset_id_two_live_contracts.access_layer_decides_semantics_001` ALREADY
  had an accurate `remediation_2026_07_27` field ("CLOSED... resolves to one contract").
- **But** `build_failure_priors.py:221-232` `_card_text()` renders `failure_summary` in
  full (still present-tense "BOTH are live today") and only truncates the
  `incident_anchor` (where `remediation` lives) to **300 chars at the END** — so the
  reviewer model read the stale claim and never saw "CLOSED." That's the precise defect.

## Fix (EDIT via qwen-coder, verified independently by rendering through the REAL `_card_text()`)
- File: `scripts/rag_verifier/failure_priors_authored_20260727.json` (2 lines).
- `failure_summary` reframed: "BOTH are live today" → "RESOLVED 2026-07-27... ONCE
  resolved... Re-verified 2026-09-03: resolves to ONE live object — the catalog parquet."
  Kept the measured numbers as the worked historical example.
- `positive_pattern`: dropped phantom `research.duckdb::spx_15min` view citation; names the
  parquet as the only live object.
- Untouched: `canonical_lesson`, `required_auditor_behavior`, `auditor_block_conditions`
  (correctly conditional), existing `remediation_2026_07_27` anchor. General lesson +
  conditional blocker stay — card still teaches the real shape, just no longer claims
  spx_15min is one.
- **Committed to master `cb845973`** (1 file, 2 lines).

## Reseed (PM-gated; PM said "confirmed")
- Wrapper `scripts/rag_verifier/refresh_data_schemas_and_priors.sh` is **PM-GATED**
  ("does NOT run on its own"). Ran `probe` (dry) first, then `go`.
- **Host vantage confirmed** before the write (`readlink /proc/self/ns/net` =
  `net:[4026531833]`, Seccomp 0); RAG service healthy on GPU 1.
- `go` reseeded **4 dense wells** (failure_priors + data_location/table_recipes/duckdb_views
  — the 3 caught up from last night's parquet refresh) in **both roots** (full 4096d +
  small 1024d) on GPU 0 (55,675 MiB free). Wrapper's built-in verify (index rows vs staged,
  vector kind vs declared seeder) passed all collections.
- **End-to-end proof:** live RAG (`rag-search "spx_15min two live contracts"`) now serves
  `RESOLVED 2026-07-27` + `Re-verified 2026-09-03`; stale "BOTH are live today" and phantom
  view citation both gone. `failure_priors full:live small:live`.

## Reusable lessons
- **A RAG prior that says "live today" can be a day stale.** Always re-verify "is X live
  right now" against live state before acting on a discovery that cites a card.
- **`_card_text()` truncation is the trap:** an accurate remediation field can be invisible
  to the reviewer model if it lives in a field the renderer truncates. Fix the rendered
  text (failure_summary), not just the payload. Verify by rendering through the actual
  builder function, not by reading the JSON.
- **RAG corpus is writable ONLY via the refresh pipeline** (scan-stage → seed-pending →
  verify), PM-gated, from a host vantage. Never hand-edit the staged/index working area.
- The six-registry fragmentation is governance debt, NOT a design flaw — do NOT merge the
  registers. The durable fix is a cross-register integrity check (in-catalog-not-ledger and
  vice-versa, dead view paths, one-name→many-objects), which is the P4 follow-on.

## Open / next (PM-owned)
1. **P2/P3 still open** from the original discovery: 115 UNREGISTERED datasets (family-
   batched PM triage, `OPEN_ITEMS.md:18`) + missing `docs/registration_instructions.md`
   (referenced as "the governing sheet" but absent). These are the precondition for closing
   the fragmentation.
2. Optional: the cross-register **integrity-check script** (converts silent drift to a
   visible report) — the durable answer to the "no diff, no error" class.
3. The reseed touched 3 wells beyond failure_priors (data-table catch-up) — expected/harmless,
   flagged for the record.
