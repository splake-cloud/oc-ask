# 2026-10-04 — no-mid policy SUPERSEDED (PM ruling) — RAG changed to match

## The ruling (PM, verbatim intent)
- The no-mid policy (HC#1 / `.ai/no_mid_policy.md` — "executable debit/credit/PnL from bid/ask SIDES,
  never the mid") is **superseded**. No ambiguity.
- **New default:** mid is used for study results / write-ups, and that must be noted ("mid-priced").
- **Rationale (PM):** bid/ask on options — including and especially multi-leg structures (butterfly,
  iron fly, "fly" vertical spread) — is not reliable: the data provider's bid/ask is **estimated** and
  does NOT reflect actual trading-book execution levels.
- **Friction:** the PM applies the bid/ask spread to results off the PM desk.
- Bid/ask side pricing is used ONLY when the PM explicitly pushes it.

## What was changed in the RAG (this session, pi seat jett-8011 / qwen3.8-27b-fp8)
8 authored cards across 4 producer files (all in `scripts/rag_verifier/`):
- `build_contracts.py` (well `data_contracts`): `no_mid_pricing` (rewritten, v2026-10-04, new title
  "pricing convention — MID default; no-mid policy SUPERSEDED"), `spx_options_view` (point 5 no longer
  directs side pricing), `fly_entry_premium_pct_mid_label` (exception framing → superseded),
  `spx_long_put_fly_debit` (side-based entry_debit marked HISTORICAL study contract).
- `build_domain_facts.py` (well `domain_facts`): `no-mid-policy` fact rewritten; common_misuse is now
  "asserting old HC#1 as standing / treating vendor bid/ask as reliable"; severity hint
  `vendor_bidask_reliability_is_blocker_candidate`.
- `harvest_internal_symbols.py` (well `internal_symbols`): `mid-price` alias re-pointed (DEPRECATED now
  refers to the no-mid policy itself); `.ai/no_mid_policy.md` vocab entry annotated SUPERSEDED.
- `harvest_research_methods.py` (well `research_method_contracts`): `transaction-cost-slippage` — must
  state pricing convention (mid vs bid/ask); default MID.

Mechanics (per RAG's own `rag-refresh-existing-well` card): scan-stage ×4 groups → read staged JSONL →
seed-pending --root all (dry-run then live; 4 dense wells, full+mid on GPU2, small CPU) → status all
live. Verified: (a) live probe "no-mid policy superseded …" → top-8 all new cards (11.56→4.13);
(b) original query "mid vs bid/ask pricing on butterfly or fly trades" → new doctrine top-4;
(c) staged-vs-live diff (lancedb, collection:source_id normalized): **12/12 PASS**
(missing=0, extra=0, zero_vectors=0 on full/mid/small).

Commit `0c4d8c5a` pushed (4 files only; tree had pre-existing dirt left untouched). Agent-Print trailer.

## Settled facts worth keeping
- `no_mid_policy.md` was **already removed from the doctrine_clauses harvest** (2026-08-17 PM ruling) —
  the no-mid doctrine lived ONLY in the authored cards above, so no L1 doc edit was needed for the RAG
  change. `.ai/no_mid_policy.md` and `.ai/CANONICAL_RECONCILIATION.md` still contain the old text on
  disk (not harvested; no RAG impact) — PM may want them marked superseded separately.
- `no_mid_policy.md` removal + this supersession = the no-mid line is now fully retired in the RAG.
- Precedent chain: INT-0212 (credit-fly study mid-priced by PM instruction, historical) → 2026-09-04
  PM ruling (decision-time marks mid-based in `fly_paths`) → 2026-10-04 (mid is the DEFAULT).
- Sealed-study numbers remain side-based by construction (stored `entry_debit`,
  `fly_value_liquidation`/`fly_value_worst_fill`) — cards now say: state which convention a cited
  number follows.

## Open / next
1. **Study write-up** ("use mid for this study write up results" — the study is from a DIFFERENT
   session, not identified here): the RAG now returns the ruling on retrieval, so that session should
   re-ground and write the write-up with mid + the bid/ask-unreliability statement. NOT done here.
2. `scripts/_no_mid_policy_denylist.py` is still a live script (scripts_registry card: "project-wide
   no-midpoint-price policy denylist") — it enforces the old policy; PM decision: retire or keep.
3. A formal INT card for this ruling would live in the `ontology_decisions` well, which harvests from
   `/data/research_agent` (separate repo/governance) — not done from this seat.
4. First message of this thread also asked to "query the RAG on mid vs bid/ask on butterfly/fly" —
   answered pre-ruling (old cards); re-query post-ruling if needed (it now returns the new doctrine).

## 2026-10-05 continuation (same RAG thread, pi seat jett-8011)
- Full-well freshness check: serving (mid) + small roots 100% current; FULL root 9/30 wells behind
  (45 new ontology_decisions cards + 2 single cards + text updates) after a 10:24 manual scan-stage
  by another active session; no RAG cron exists.
- PM ordered review + commit of that session's uncommitted rag_verifier edits. Review verdict:
  all commit-worthy; verified (out-of-spread probe reproduced K3790 0.2491 / K3850 0.2836; ORATS
  options-101 definitions fetched live; futures registry 48 roots/18 cols vs real bytes; pending
  decisions 189 recs/96 OPEN; gate 4/5 with the 1 FAIL pre-existing at HEAD: reasoning_precedents
  wrapper-only). One wording defect found+fixed: no_mid_pricing 'mean ~4.55 SPX pts' was the MAX
  (measured max 4.609, mean 0.452) → 'diverge up to ~4.6 (mean ~0.45)'.
- COMMITTED + PUSHED (2 commits, both Agent-Print, authorship noted in message):
  `8cf943ed` system_processes registration (kb_collections + rag-search + oc_seat_stage + 3 seat
  bindings — was live-but-uncommitted since 10-02); `d70f0411` no-mid MID revision + futures
  registry card (stale since 09-22) + ontology_state pending decisions.
- REMAINING: `seed-pending --root all` to close the 9 full-root pending wells (coordinate with the
  authoring session, still active; data_contracts will re-stage with the wording fix included).

### 2026-10-05 second continuation (stale-card fix + guard repurpose, PM-ordered)
- **Item 1 resolved**: the 4.55 in `spx_options_theoretical_values_not_prices` was
  **verified CORRECT** (exact repro: 2026-06-30, quoted puts bid>0 AND ask>0,
  4,979,316 rows → mean 4.547 / max 2374.56; IV clamp range -0.0..10.0 also checks
  out). But the card's opening clause asserted the superseded side-only rule →
  fixed: now "Study pricing uses (bid+ask)/2 of the raw NBBO columns (PM ruling
  2026-10-04 — mid is the default and must be noted); side columns describe
  executable fills, not the study mark; never use *Value or IV as a price."
  Version 2026-10-05. **Committed `0e2832ca`, pushed.**
- **Item 2 = option 2 chosen**: `scripts/_no_mid_policy_denylist.py` repurposed
  as the model-value-as-price guard. Tokens = the four *Value columns
  (case-insensitive); all mid tokens removed (mid naming is now sanctioned);
  IV columns intentionally not token-banned (legit vol features — rule stays in
  RAG). New entry point `assert_no_model_value_in_source`; `assert_no_mid_in_source`
  kept as compat alias so the sealed 2026-05 consumers (flymicro pilot, MFM v1)
  import UNCHANGED — zero consumer edits. Verified: unit tests (mid naming + IV
  features pass; all four *Value tokens caught), whole-file scan of both sealed
  consumers passes. **Committed `b207a1fc`, pushed.**
- **RAG closed**: scan-stage data_contracts + scripts_registry → staged verified →
  `seed-pending --root all` → **all 26 wells live on all 3 roots** (also closed
  the 9 stale full-root wells from 10:24). Live probe: fixed card served at
  version 2026-10-05, top-ranked.
- **Flagged, NOT changed (out of scope, PM judgment)**: two cards still describe
  the old HC#1 without a SUPERSEDED marker — `lifecycle_contracts` "code no mid
  price" (v2026-09-27) and `internal_symbols` "HC#1" (v2026-06-17). Both are
  scoped to trade-decision/execution, which the ruling may not have touched
  (ruling covers study pricing) — needs a PM call on the study-PnL vs
  execution-PnL boundary.
- **Open**: `.ai/no_mid_policy.md` itself — still on disk, unmarked. The RAG
  cards say SUPERSEDED; the file's own header does not. Mark it or retire it: PM.

## 2026-10-05 continuation #2 (card fix + guard repurpose, pi seat jett-8011)
- Verified the OTHER "4.55" (`spx_options_theoretical_values_not_prices` card, 2026-07-06 probe):
  **exact match** — 2026-06-30 quoted puts, all expiries, 4,979,316 rows → mean 4.547, max 2374.56.
  Legitimate mean (unlike the mislabeled revision-card number). Card's IV-clamp claim also verified
  (putMidIv range (-0.0, 10.0)).
- **Commit `0e2832ca`**: that card's stale opening clause ("must use bid/ask side price columns only"
  — superseded HC#1) replaced with the current rule; stats kept; version → 2026-10-05.
- **Commit for the guard** (option 2 per PM): `scripts/_no_mid_policy_denylist.py` repurposed —
  mid tokens REMOVED (mid naming is now sanctioned), denylist = the four *Value tokens
  (putvalue/callvalue/extputvalue/extcallvalue, case-insensitive). New entry point
  `assert_no_model_value_in_source`; `assert_no_mid_in_source` kept as compat alias so the two
  sealed 2026-05 consumers (flymicro pilot, MFM v1) import UNCHANGED. IV columns intentionally not
  token-banned (legit vol features) — "no IV as price" stays in the RAG. util_book_reconstruct only
  docstring-references the module (its size-only design note stays accurate).
- Verified: guard unit tests (mid naming + IV features PASS, all 4 *Value tokens caught),
  whole-file scan of both sealed consumers passes, py_compile both files.
- RAG: scan-stage data_contracts + scripts_registry → seed-pending --root all → **all 26 wells live
  on all 3 roots** (closes the 9 stale full-root wells too). Live probe: fixed card served at
  version 2026-10-05, doctrine set coherent (8 cards).
- Remaining review candidates (NOT changed, flagged): lifecycle_contracts "code no mid price"
  (v2026-09-27) and internal_symbols "HC#1" cards still state the old constraint without a
  SUPERSEDED marker — their scope is trade-decision/execution, which the ruling arguably left
  intact; PM call on whether to mark them.

## 2026-10-05 continuation #3 — HC#1 source re-scope (PM-approved, executed)
- Verified the two flagged cards: both are faithful mirrors of CR §Hard Constraints #1
  (internal_symbols card AUTO-PARSES CR via `hard_constraint_cards()`; lifecycle card is a
  hardcoded tuple). Neither touches *Value/model values — pure mid-price policy. Scope is
  execution/trade-side, but "P&L"/"recommendations" straddled the research boundary.
- PM approved the full scope (probe gold → update; CLAUDE.md bullet → include). Executed:
  - CR v0.8 → v0.9: HC#1 scope disambiguated (executable P&L, trade recommendations) +
    study-pricing default sentence; change log row added (notes missing v0.7/v0.8 rows —
    pre-existing gap from the 2026-06-06 relocation, NOT retro-created)
  - .ai/no_mid_policy.md: header AMENDED marker (executable-scope body untouched)
  - CLAUDE.md:304 bullet updated
  - probe_set_v1.yaml uc2-01 gold updated (was pre-2026-05-02 wording; FAIL + HC#1 unchanged)
  - harvest_lifecycle_contracts.py: code-no-mid-price card text
- **No separate validator prompt file exists** — bench_probes.assemble_doctrine() bundles
  CLAUDE.md + CR L1 sections at dispatch; verified the 51.6KB prefix carries the new text.
- RAG: internal_symbols + lifecycle_contracts re-staged + seeded; all 26 wells live ×3 roots;
  live probe returns the re-scoped text.
- **Committed `3e7dd403` + pushed.** Sealed artifacts untouched.
- NOTE for future sessions: the edit tool twice reported spurious "failed to match" on
  CANONICAL_RECONCILIATION.md / CLAUDE.md while the edits actually landed (all five diffs
  verified word-for-word vs intent before committing). If that happens again: diff vs HEAD
  before retrying — do NOT double-apply.

## 2026-10-05 continuation #4 — RAG ops runbook (doc only, per PM "1")
- PM asked whether a rag-ops agent is valuable → assessed: doc = high value /
  low cost / agent-independent; agent = medium (context isolation, structural
  no-write, vantage-correct reporting); REFRESH delegation = low. PM chose
  "1" = build the doc only.
- **`docs/RAG_OPS.md`** (338 lines) committed `c8936540` + pushed. Sections:
  S0 safety contract R1-R6, S1 system map, S2 HEALTH (7 steps + verdict table),
  S3 DIAGNOSE (card->producer trace + staged-vs-live diff recipe via
  kb_collections.connect().open_table() + 4-link freshness triage), S4 REFRESH
  (gate sequence), S5 vantage & environment, S6 known-failure-modes table
  (incl. today's spurious edit-tool reports), S7 receipts.
- All commands verified in-session before writing. Companion to docs/RAG.md
  (reference/checklists A-H) — no duplication, pointers only.
- 2026-10-05: RAG_OPS.md pointer added to the system_processes refresh card
  (commit 564a3f52, pushed) — runbook now discoverable from RAG-grounded
  seats. Reseed landed via a concurrent session's seed-pending (verified in
  live rows all 3 roots). Same commit fixed RAG_OPS S3.2 read API:
  table.to_list() doesn't exist -> search().limit(10000).to_list().
  Still deferred: rag-ops agent registration, AGENTS.md pointer line.
