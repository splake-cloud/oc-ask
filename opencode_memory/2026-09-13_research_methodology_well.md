# 2026-09-13 — research_methodology RAG well installed + mandatory research-grounding doctrine wired

Session: pi seat, session_id `01a0982a-0f07-7317-97b2-3c736603977b` (verified = live PI_SESSION_ID at receipt close). Three deliverables, all committed + pushed: RAG well install, research-grounding doctrine, scoped lexical fallback.

## 1. New RAG well `research_methodology` (agentic_trading, commits 933fb00d + 26ef3100, pushed)

65 advisory reference cards (50 technical methods T01–T50 + 15 research principles M01–M15) from
`/tmp/research_rag_well.zip`, installed per RAG.md Checklist B (new well). PM decisions: well name
`research_methodology` (distinct from `research_method_contracts`); source in-tree at
`scripts/rag_verifier/research_methodology/{cards.jsonl, retrieval_examples.jsonl, README.md,
editorial_notes.md}` (sha-verified vs zip; only cards.jsonl ingested); `text` as-is; all four gates;
GPU floor normal else CPU immediately.

- Harvester: `scripts/rag_verifier/harvest_research_methodology.py` — 8-field schema,
  `source_id = <ID>#__methodology__` (canonical IDs preserved; `related` refs intact), text
  byte-identical, validates 65/unique-ids/related-resolvable, `--print` mode.
- Registered: kb_collections (24 wells, `refresh: cold`, all 4 gates), refresh_planner GROUPS
  (`seeder: dense`, fingerprint over cards.jsonl), rag-search, oc_seat_stage GROUNDING_BINDING,
  lane/agents ×3. Seat-grounding gate 11/11 PASS.
- Seeded **CPU** (max GPU free 20.6 GB < 28 GB full floor; floor not lowered): full=live small=live,
  `staged=65 live=65 missing=0 stale=0 zero_vectors=0` both roots.
- New well ⇒ `verifier-rag-small.service` restart required (registry cached at startup; an unknown
  collection rejects the WHOLE request — verified live before restart). Restart needed sudo password
  (PM ran it). `:8765` = FULL root, 8B embed + 8B reranker, gpu2.

**Relevance (26 example queries):** 22/26 retrieve a listed relevant card, 20 at rank 1. Four
zero-results: GARCH/file-count = reasonable abstention (PM); the other three
("which fly should I enter…", "among +50% touchers…", "all-expiry → same-scope 0DTE") =
**retrieval-quality gaps, mechanism proven** (verify/rm-well-miss-{inspection,poolmax}): expected
cards ARE in the candidate pool (dense rank ≤12, BM25 rank ≤7 in 8/9) but the resident 8B
cross-encoder scores the entire pool negative (pool max −0.25 / −1.5 / −2.25) and the default
**0.0 floor on raw signed logits** (VERIFIER_KB_RERANK_MIN_SCORE unset) drops everything → n_cards=0.
PM: global floor stays unchanged. **RESOLVED in two passes (commits 98eb27f0 + de65fd92, same session).** Pass 1: scoped lexical fallback in `small_service._search` on card triggers (len≥3). PM then ruled the triggers are candidate-retrieval vocabulary, NOT admission rules — GARCH (standalone method name) and FAIL (generic status word) must not bypass reranker rejection. Pass 2 (de65fd92): fallback now fires ONLY on an explicit per-card phrase map in `LEXICAL_FALLBACK`: M01 ["which fly should i enter","fly entry selection","entry time selection"], T29 ["+50% touch"], M02 ["all-expiry","0dte"], M15 ["port over"]; M01 card wording passed with the same three phrases (triggers + text Triggers line), well reseeded both roots. Per-well zero-survivor condition, 2-card cap, raw logits, flag preserved. Final verify (35 queries + 8 paraphrases): 29/32 + 3/3 wrapper identical; MISS1→M01 (−0.625), MISS2→T29, MISS3→M02+M15; GARCH and failing-test abstain; 'Should I enter a fly at 11:30?' abstains by design (no standalone fly/enter/11:30 phrases); both fly paraphrases retrieve M01 as normal rerank survivors.

Zero-VRAM inspection endpoints (added 2026-09-11, used here): `POST :8765/embed` (RAW vectors,
`prompt_name="query"`, client L2-normalizes) and `POST :8765/rerank` (resident 8B cross-encoder,
raw signed logits, ≤256 texts).

## 2. Mandatory research-grounding doctrine (research_agent, commit 247d1b1, pushed)

`/data/research_agent/AGENTS.md`: new `## Mandatory research grounding` section (between `## RAG`
and `## Study state`): three mandatory sources — `research_methodology`, `research_method_contracts`
(:8765) and `paper_corpus` (:8090) — consulted before materially reasoning from prior research, even
when no useful retrieval is expected; per-source record (SEARCH EXECUTED / QUERY / HITS RETURNED /
RETRIEVALS ACCEPTED / NOT ACCEPTED); no claim of consultation without an executed+observed search;
no rationale required unless PM/phase asks; zero-hit and all-rejected are valid but must be reported;
unreachable source reported explicitly, never silently substituted. **Scope: top-level runs only** —
8011 idea/blueprint author, 8011 build-spec author, 8012 build lead, fresh 8012 semantic KASA,
fresh 8011 final adjudication. Delegated workers (8012 semantic-worker, 8081 fast-coder) inherit the
parent's grounding record; no repeated three-way consultation unless the mission requires it.

One-line pointer ("Complete and report the mandatory research-grounding check required by AGENTS.md
before finalizing this phase.") in `prompts/{blueprint,build_spec,semantic_builder,semantic_kasa,
adjudicator}.md` at each finalization anchor; NOT in `semantic_worker.md` / `fast_coder.md`.
`blueprint.md` additionally carries a `## Mandatory grounding audit` section requiring the actual
`MANDATORY GROUNDING` block (three sources × five fields) in the blueprint output — no prose
justifying selections unless PM asks.

## Open / next

- Open: none for this thread. Both commits (98eb27f0, de65fd92) pushed to origin/master.
- Note: pass-1 commit 98eb27f0 (trigger-based fallback) was superseded by de65fd92 in the same session — history kept, not rewritten.
- Zip's `manifest.json` + `source/uploaded_50_original.md` NOT committed (outside PM's closed file list); checksums live only in `/tmp/research_rag_well/`.
- Both repos' session commits pushed: agentic_trading up to `de65fd92` (well install + doctrine wiring + lexical fallback passes; an earlier push carried one concurrent-session commit 33b990e0 gamma-magnet study — flagged to PM), research_agent `36b7341..247d1b1`.
