# 2026-09-20 — credit_fly (short 0DTE SPX put butterfly) — scoping + idea gate banked

Session: pi seat (jett-8012, qwen3.8-27b-fp8), /data/agentic_trading. PM mission:
scope whether the CREDIT side (selling the fly) of the 0DTE SPX put butterfly is a
better trade than the debit side (apparently negative EV), what win rate it gets,
and what the conditional variables are. PM: qwen-coder/fast-coder unavailable; 8012
seats for read-only fan-out; 8011 writes.

## What was built (all committed, b30e2ea2, Agent-Print trailer)

- `studies/credit_fly/scoping.md` — full scope: mark asymmetry, inherited variable
  set, data inventory, Phases 0–6, kill gates, delegation plan.
- `studies/credit_fly/idea.md` — canonical 8-section idea gate artifact
  (idea.template.md form). Gate: `READY FOR BLUEPRINT — awaiting PM authorization`.
- `studies/credit_fly/receipts/idea_grounding_2026-09-20.md` — grounding record
  (3 RAG query rounds with accepted/not-accepted; 3-way EXPLORE fan-out
  file:line evidence; data probes).

## Key facts settled (grounded)

- Debit negative-EV premise CONFIRMED, not folklore: full book n=8,635, hit 44.2%,
  EV −0.33 D, median +1.02 D (`studies/0dte_fly/SPX_0DTE_FLY_DECISION_CARD.md:132`,
  reproduced `repeatable_setup_m3_report.md:60,157`). Median positive ⇒ debit win
  rate >50% ⇒ the "credit = higher win rate" prior is likely INVERTED (Phase 0
  settles with exact numbers).
- Core structural asymmetry: debit pays the ~$0.30 package spread once (side-aware
  entry, executable-mid decision exit); credit pays it TWICE (side-aware entry AND
  close) ⇒ first-order credit EV ≈ +0.33 − ~0.30 ≈ break-even. Q-C in idea.md is
  the validity gate for this.
- Seller side already tested ONLY on the 7 debit-hostile cells: script2i
  (evidence_archive.md, 2026-05-04) 35/35 (rule×cell) negative EV, seller win rate
  20–44% — those cells are ratified NO-GOs, excluded from the candidate space.
  Untested surface = full book + debit-favorable cells (M3 family R3+T≤25 +0.172 D
  is the warm start + C3 comparator).
- Study framing (PM revisions, incorporated in idea.md §1): first pass =
  re-optimization of the harvest objective over the debit-IDENTIFIED variable space
  (established input; no per-variable re-validation; sign flips = results, not
  tests); additional variable discovery OPEN but second pass, gated (enrichment if
  first pass strong; main line if weak/NO-GO); second objective = the edge
  trade-off / harvest window T*(state) = point in time where the credit is still
  fat while the conditionals point to premium collapse.
- Data (probed): `warehouse.warehouse.fly_trades` 17,411 rows 2021-05-14→2026-09-18
  (both body grids; `value_at_1555` 49.7% coverage, debit-mark — R1);
  `stg_spx_options` (4.6 GB) for credit-mark re-derivation; `pools/uw_gamma`
  2025-12-12→2026-09-18 only (192 days, R2); `iron_fly_weekly_substrate_v2`
  cross-check only (different structure).
- No butterfly work exists in /data/research_agent (verified zero-hit).

## Rulings (PM, 2026-09-20, model suggestion ratified)

- D1: EV floor = +0.10 D/trade on the credit-side (double-spread) mark.
- D2: win-rate floor = 60% AND ≥ +5 pp over the debit best family.
- Delegation: 8011 (qwen38-collab) writes; 8012 (qwen38-reviewer) read-only fan-out;
  author ≠ reviewer.

## Open / next

- PM authorization for blueprint authoring (gate is READY; per transport, do NOT
  start the blueprint without explicit authorization; handoff = set §8 to
  AUTHORIZED, commit idea.md + receipt path-scoped, report commit/blob/SHA256,
  ontology ledger birth + authorize).
- Phase 0 (read-only SQL on fly_trades: debit vs credit-mirror win rate / EV /
  median per mark scale) is the first executable step after blueprint.
- Blueprint obligations left open by design: (θ_c, θ_p) harvest-window thresholds,
  TP/stop grid, estimators, OOS architecture, re-derivation pipeline, multiplicity.
