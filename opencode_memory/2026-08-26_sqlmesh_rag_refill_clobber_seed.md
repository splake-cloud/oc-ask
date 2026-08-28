# SQLMesh reference RAG: re-fill after scan-stage clobber, 3 opus reviews, seeded live

**Date:** 2026-08-26 · **Seat:** oc-ask · **Topic:** sqlmesh_reference RAG re-fill + validation + seed

## What happened

1. **scan-stage clobbered the reviewed staged file** — the fingerprint check said "input changed" because the manifest hash (`00aec0b1`) didn't match the reviewed staged file hash (`428c59ef`). scan-stage re-harvested from stale YAMLs, overwriting the reviewed content back to N/A (51 N/A occurrences).

2. **Re-filled 13 cards** via qwen-coder delegate (211 chunks, 194 target).

3. **Opus review #1 (REJECT)** — found 6 errors:
   - E1: "50+ models" fabricated (should be 26)
   - E2: Model lists wrong (Python/SQL misclassified, typos, missing models, DDL invariant false for Python models)
   - E3: context.table() DataFrame example in our_usage
   - E4: resolve_table legitimized in invariant
   - E5: 5 contradictory our_usage claims (forward_only, external_models, dev-env TTL)
   - M1: db__<env> placeholder

4. **Fixed all 6 errors** and re-ran opus review.

5. **Opus review #2 (NOT APPROVED)** — 2 remaining errors:
   - E1: 26 → 25 (intraday_base is a helper, not a SQLMesh model)
   - E2: _intraday_base still in Python models list

6. **Fixed E1/E2**, opus review #3 (APPROVED).

7. **Seeded both roots** (small + full) via `seed-pending`, then `mark-live`.

## Key facts
- **Live now:** 211 chunks across 25 YAML cards (13 filled, 12 pre-existing)
- **Small root:** /data/parquet/verifier_kb_small (0.6B embedder, dim 1024) — LIVE
- **Full root:** /data/parquet/verifier_kb (8B embedder, dim 4096) — LIVE
- **Staged file:** /data/parquet/verifier_kb/staged/sqlmesh_reference.jsonl (sha256 c2762caa...)
- **YAML source-of-truth:** Still stale — next scan-stage after any model file change will re-harvest from stale YAMLs and clobber again

## Open items
1. **YAML backport needed** — the 13 YAML cards need updating from the reviewed JSONL content, plus a harvester template extension for verbatim our_usage text blocks
2. **claude code delegate** from earlier session never delivered — task was lost
3. **E5 unresolved** — the contradictory our_usage claims are annotated but the source YAMLs still claim features we don't use (forward_only, external models, dev-env TTL)

## Verified commands
```bash
# Live service returns filled content
curl -sS -X POST "http://127.0.0.1:8765/search" \
  -H "Content-Type: application/json" \
  -d '{"query":"strptime src.tradeDate time column","collections":["sqlmesh_reference"],"k":3}'
# Returns chunks with strptime(src.tradeDate, '%Y-%m-%d')::DATE AS trade_date

# Status
.venv/bin/python3 scripts/rag_verifier/refresh_planner.py status --root all | grep -A2 sqlmesh_reference
# full=live small=live rows=211
```

## Phase 2: review + verify + red-team (same day, after seed)

Three independent passes: mechanical scan, qwen-coder EXPLORE claim-verification
(~160 claims: 160✓ / 5 wrong / 7 unverifiable), claude-opus-4-7 adversarial
red-team (6 BLOCKERS + 8 MAJOR + 7 minor). Note: red-team ran from sandbox
netns — its "service offline" note was a vantage artifact, live probes from
host worked.

Fixed + re-seeded (sha f6f13773, 211 rows live on both roots):
- B3: restatement_scope_by_kind — table had WRONG defaults (SEED True→False,
  UNIQUE_KEY True→False; authoritative: kind.py defaults, True-group =
  INCREMENTAL_UNMANAGED, SCD_TYPE_2 (by time + by column), MANAGED Literal[True])
- B4: context.table() documented DEPRECATED in 0.236.x (context.py:203-208);
  deprecation note added to all 3 practice chunks
- B5: python_model_template rewritten to match iv_percentile_daily.py exactly
  (columns=COLUMNS, context.fetchdf not duckdb.sql, t.Any params, python-form audits)
- B6: `sqlmesh clean` was mislabeled DANGER; now clean=cache only, destroy=destructive
- B1/B2 (pilot cards): OUT OF SCOPE per PM — left as-is (agent_query bait chunk
  on local_agent_guidance still ranks on "add a new model"; revisit when pilot lands)
- M1-M8: scope-bleed NOTEs defeated-in-same-chunk (fixed 4), environments_detail
  contradiction (fixed), standalone-audits false claim (fixed), camelCase rule
  softened (expiryTod is real in stg_spx_options), FORWARD_ONLY marked deprecated,
  stg_spx_options_eod added to all incremental cards, model_decorator corrupted
  template render repaired
- W1: "CAST(src.tradeDate AS DATE) or..." → strptime only (all models use strptime)
- W4: Context(path="warehouse/", config="local") was a TypeError (no path= kwarg,
  context.py:383 paths= only) → Context(paths=...) in 4 chunks
- M2/M4/m2/m4: dead provenance file-refs repointed to real docs/*.yaml cards;
  duplicated section headers deduped (0 remaining)

Pilot cards (B1/B2) deferred to pilot completion.

## Phase 3: YAML backport — TIME BOMB DEFUSED (same day)

- Harvester (`scripts/rag_verifier/harvest_sqlmesh_reference.py`) gained an optional
  `verbatim_text` override on concept/our_usage/incident — emitted verbatim when
  present; byte-identical output when absent (verified: old-vs-new harvester diff on
  unchanged YAMLs = empty).
- 24 in-scope YAML cards pin the reviewed text in `verbatim_text` (138 keys);
  structured fields kept for human provenance; 6 list→dict our_usage conversions
  preserve original bullets under `notes:`.
- Pilot cards + local_decision_axis.yaml untouched.
- DECISIVE PROOF: ran `scan-stage --groups sqlmesh_reference` (CPU-only, does NOT seed
  the index) AFTER the backport — fingerprint flipped (`input changed=True`, the exact
  condition that clobbered the first fill) → re-harvest → **0 mismatches** vs reviewed
  staged text. Reproduced reviewed content instead of reverting to N/A.
- Commits: 34728968 (local_architecture config-file rename), e3a58139 (harvester
  override + 24-card backport, 25 files).
- State: staged text == live index text (both roots live, 211 rows), marked live with
  note that no re-embed is needed (re-harvested file differs only in record metadata —
  native title/source_type/version/payload vs fill's card_id/chunk_type/metadata; the
  `text` field that embeds/retrieves is identical).

Still open:
- Pilot cards (B1/B2): local_agent_activation cites nonexistent
  sqlmesh_builder.driver.yaml (real seed: rig/seeds/sqlmesh_builder.coder.yaml);
  local_agent_guidance all-N/A bodies + agent-queries bait chunk outranks real answers
  on "add a new model". Deferred to pilot completion (PM-excluded).
- Re-harvested staged file now carries native record metadata (no card_id/chunk_type/
  metadata keys). Inert (seeder's add() never reads them) but future tooling that
  assumes the fill's 3 extra keys will find them gone.
