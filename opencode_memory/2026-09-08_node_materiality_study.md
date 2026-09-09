
## RAG card ship (2026-09-08, ~08:10 UTC) — user: "implement in line"
- **Blueprint PM-authored** (no ambiguity in the 8-field card shape — Checklist H, `build_contracts.py`
  dict entries / `build_domain_facts.py` 8-tuples): `analysis/sml_fly_verify/gamma_topology/RAG_NODE_MATERIALITY_CARDS_BLUEPRINT.md`.
- **Dispatched as two sequential EDIT envelopes to qwen-coder** (blueprint = authority, verbatim apply):
  A = build_contracts.py (4 updates + 3 new = 7 entries); B = build_domain_facts.py (2 tuples).
- **PM independent verification**: staged == builder rebuild (byte-level); diff vs git-HEAD builder output
  is EXACTLY 4 updated + 3 new (contracts, 88→91) and 2 updated (domain, 29); all else byte-identical.
- **Shipped**: scan-stage (CPU, host vantage net:4026531833) → **small root seeded (120 chunks, gpu2)** →
  §0.2 landed check small: missing=0 stale=0 zero_vectors=0 both collections.
- **FULL ROOT PENDING — GPU FLOOR**: 28,672 MiB required, max free 20,580 (gpu2; qwen3.6 :8081 co-resident
  41.5 GiB). **The :8765 service serves the FULL root** (health: kb_root=/data/parquet/verifier_kb,
  embed qwen3-embedding-8b, rerank cross_encoder 8b — NOT the small root) → **the new/updated cards are
  NOT yet retrievable on the live lane** until the full root seeds. Floor not lowered (Checklist D).
- **Receipt**: `verify/rag-ship-nm20260908.20260908T080854Z.txt` (exit=0; first attempt 080822Z failed —
  my check script diffed staged-vs-staged after re-staging; fixed by diffing git-HEAD builder output).
- **Commit** `a183522d` "rag: node-materiality finding cards — 3 new + 6 updated (harvester edits, PM-verified)".
- **RESOLVED (PM pushback, ~08:12 UTC)**: the eviction question was a FALSE DECISION — the no-eviction
  path existed in the planner all along: `seed-pending --root full --remote-embed
  http://127.0.0.1:8765/embed` (kb_store `_RemoteEmbedder`, added 2026-09-06, whose docstring
  describes THIS exact 20,582-vs-28,672 MiB situation; the planner probes remote model/dim identity
  BEFORE any well drop and skips the GPU floor for a remote encoder). Full root seeded: 120 chunks,
  zero VRAM in the seed process, no model touched.
- **Final state**: both roots live/landed (missing=0 stale=0 zero_vectors=0, both collections);
  Checklist E — all 5 phrases retrieve target cards at rank 1 on the served lane (keeper_candidate_rule
  4.25 / gamma_node_size_calibration 5.5 / node_materiality_study 4.31 / updated
  gamma_intraday_0dte_key 5.31; domain card co-retrieves at 2.12).
- **Receipt**: `verify/rag-live-nm20260908.20260908T081256Z.txt` (exit=0). **Commit** `029b2f12`.
- **Semantic retrieval check (PM asked: "did you check with natural inquiry?")** — the first Checklist E
  pass used card vocabulary (triggers), which does NOT test what a fresh session would ask. Redone with
  10 natural-language inquiries incl. 3 trap questions: all 10 retrieve the intended card at rank 1 (or
  #2 beside its parent), traps defused: ~3,000-threshold question -> gamma_node_size_calibration
  (retires it) #1; "gamma 500 at touch = a node?" -> node_materiality_study + calibration #1-2;
  "50% of the way to the wing width = the 50% touch?" -> spx_long_put_fly_debit (new denominator
  warning) #1. Receipt `verify/rag-semantic-nm20260908.20260908T081506Z.txt`, commit `ab2b6630`.
  Lesson: retrieval acceptance must include natural-phrasing probes, not just trigger-word probes.
- **Lesson (process)**: when a floor/gate refuses an action, read the gate's OWN comment block before
  presenting options — kb_store L52-58 had already documented the correct answer for this exact box.
