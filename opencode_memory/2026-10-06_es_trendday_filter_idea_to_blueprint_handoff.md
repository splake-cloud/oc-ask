# 2026-10-06 — es_trendday_filter: idea developed → verified → AUTHORIZED for blueprint (handoff banked)

pi seat jett-8011 / qwen3.8-27b-fp8, session `01a10ed0-0c8d-757c-b877-41b4461fcd6d`, working dir `/data/research_agent`.

One long session that took the `es_trendday_filter` study from a fresh idea all the way to an authorized, independently-verified blueprint handoff. The study is a **separation problem**: among the days the PM's fixed trend-day signal fires, find decision-time (at the trigger moment t0) information that separates GENUINE ES trend days from FALSE POSITIVES, so each fired signal can be **bucketed by strength = (definition strictness, incl. K) × (conditional probability of a genuine trend given the decision-time conditions)**.

## The arc
1. **Idea developed + grounded** (mandatory 3-source: research_methodology M08/T08/M11/M10; research_method_contracts event-study/post-selection/two-stage-gate/FDR; paper_corpus 5 accepted / 4 rejected). Study registered in the ontology ledger (`birth` → IDEA).
2. **Population probe v1** (wick test / t0-close label): 1,283 flags / 1,684 eligible, 62.2% TP / 37.8% FP. PM eyeballed 3 days and issued **two encoding corrections** (R-00107, R-00108).
3. **PM corrections** — R-00107: the false-positive label reference = **the broken level (PMH/PML), NOT the t0 close** (FP iff max favorable excursion from the level < 10.0 pts after t0 through 16:00). R-00108: the clean move is **part of the trigger** (a qualifying reclaim must launch ≥5.0 pts from the level within 15 min) + the retest test is **close-based** (a wick that closes back inside does not count).
4. **Config sweep v2–v8** → working no-hold base (v6): 1,021 flags, 83.3% correct / 16.7% FP.
5. **"Hold over/under VWAP" resolved through iteration** (PD-00119 / R-00109): PM — "oscillation is the definition of chop" → encoded as a **cap K on the number of 5-min-close VWAP crossings in the break→t0 window** (a single pullback that is reclaimed is a test, not a failure). K mined 0..12; **K=4/5 = precision peak**.
6. **Working candidate (K=4): 852 flags (50.6% of eligible), 84.9% correct / 15.1% false positive; 2020–23: 83.7% → 2024–26: 86.4%.** K=4 is the strictest value consistent with the PM's day-level calls (9/30 has exactly 4 crossings; K=0 excludes it).
7. **Independent 8012 completion review** (`verify/idea_completion_review_2026-10-06.md`): **READY FOR BLUEPRINT**, 0 HIGH / 0 MED / 5 LOW. All load-bearing numbers reproduced exactly; full K grid matches cell-for-cell; all 3 PM day-calls re-derived from raw bars; all 3 ruling rounds faithfully carried.
8. **Blueprint handoff** — gate set AUTHORIZED, ledger transitioned, handoff brief banked.

## Trigger encoding (frozen, Reading B)
- **Trigger**: break PMH/PML → retest → the test fails (level holds) → the reclaim **launches a clean move**; t0 = first qualifying 5-min close reclaiming the level. A day that breaks and never returns does NOT fire (retest-and-hold days only).
- **Test = close-based**; **label reference = the level**; **clean move ≥5.0 pts from the level within 15 min** (pending PM confirm); **one signal per day** (earliest of up/down); early-close days excluded.
- **Hold = VWAP-crossing cap K** (working K=4, validated band {4,5,6}; final K = blueprint test item, selected on discovery 2020–23, confirmed 2024–26). Crossing count on 5-min closes; 1-min sensitivity = blueprint robustness check.
- **PMH/PML** = premarket session high/low (04:00–09:30 ET, finalized 09:30). **VWAP** = session-anchored RTH 09:30, premarket excluded, typical price (pending PM confirm). **EMA21** = 21-period EMA on 5-min closes (platform seed from bar 1).

## Key facts (with paths)
- Study: `/data/research_agent/studies/es_trendday_filter/` — `idea.md` (gate = AUTHORIZED FOR BLUEPRINT), `receipts/`, `scripts/flag_set_probe.py`, `outputs/`, `verify/`.
- **Committed idea identity** (what the blueprint dispatch binds): commit `2c2fcc23`, blob `5473d293…`, sha256 `601fc375…`.
- **Ledger**: `IDEA → AUTHORIZED` (audit both SEAT_8011); primary datasets linked: `es_continuous_databento current-2026-10-06` (sha `7b62e781…`, the file the probes ran on — the stale ledger `v1` record `8359bc67…` was left untouched) + `vix_daily v1` (sha `f50f1edc…`).
- **Probe**: `scripts/flag_set_probe.py` (parameterized; `cond_mode=hold_k` + `hold_tol=K`). Working candidate `outputs/flag_probe_k4.csv`; K grid `outputs/flag_probe_k0..k12.csv`; no-hold base `outputs/flag_probe_v6.csv`.
- **PM rulings**: PD-00112..00119, R-00102..00109, INT-0314..0316 (idea-phase decision trail in `receipts/pm_ruling_2026-10-06_idea_decisions.md`).
- **Split (frozen)**: discovery 2020–2023, confirmation 2024–2026. **No pre-set operating floor** — report the full joint frontier (precision × true-trend retention × FP-removal); PM decides the operating point at result. **FDR-BH q=0.10** at discovery + period replication at promotion; full search provenance (M08).
- **Data**: `/data/parquet/es_continuous_databento/es_continuous_v1.parquet` (ES front-month continuous 1-min, 2010→2026-10-05, refreshed 2026-10-05 23:32); `/data/parquet/vix_daily/vix_daily.parquet`. Gamma (F8) deferred to follow-up (coverage ≤203 days, 2025-12→2026-10 only).

## Open (resolved at the blueprint review — NOT blockers)
1. Clean-move magnitude: 5.0 pts / 15 min — confirm or adjust.
2. VWAP anchor: RTH 09:30, premarket excluded — confirm or adjust.
3. (Optional) 10/02 eyeball: fires 10:35, +7.5 pts, never reaches PMH+10 → classified false positive; PM had not yet eyeballed it.

## Next (the new agent does this — see the handoff brief)
`receipts/blueprint_handoff_2026-10-06.md` — a fresh 8011 session verifies state = AUTHORIZED + idea commit = `2c2fcc23`, then dispatches supervised blueprint authoring **once**: `python3 /data/research_agent/tools/dispatch_blueprint_author.py --review-ready --study es_trendday_filter` (held live claim → MONITOR, never a second). The dispatched worker authors `specs/blueprint.md` (+`method_applicability.yaml`), does the mandatory 3-way grounding, seals the manifest, commits blueprint+manifest in ONE commit, dispatches the blueprint validator, and the seat monitors to a terminal claim state, assembles the PM review packet, and STOPS for ratification. It does NOT produce the build spec and does NOT ratify.
