# 2026-09-29 — SPX vertical spreads research + concept brief (session 01a0ebdc-ce62-7046-aee0-f48f88dac030, pi seat jett-8011 / qwen3.8-27b-fp8)

**User ask:** "top ideas on how to use vertical spreads on SPX, with conditional
variables (gamma size, regime) that increase the expected value and odds of daily
winning trades" → then "what are working, modelable definitions of a trend day" →
then "drop this research in /data/research_agent/studies/spx_vertical as a concept
brief (not a formal idea)" → commit + push.

## What was done

1. **Pass 1 (knowledge store only, no live research needed):** complete framework
   already in the store — 4 daily gates with evidence:
   - **BOD GEX regime**: Neg GEX → 1.70× stop width / ~59% size or flip long;
     High GEX → full-size short premium. 887-day study (Jan 2022–Aug 2025),
     Neg vs High GEX intraday RV 13.7% vs 8.1%, Welch t = 11.95, p < 0.0001,
     R² ≈ 0.05. (theintrinsicinvestor.com/research/0dte-gamma-trap)
   - **IV percentile/rank** (high → short verticals, low → long), **IV skew bands**
     (25Δ put skew > 25th pct of range → short put spread OK; flat <3 pts preceded
     Aug 2015 / Feb 2018), **VIX term structure** (contango <0.95 sell, 0.95–1.0
     −50% size, backwardation no short premium). (volatilitybox.com, schwab.com,
     support.spotgamma.com)
2. **Pass 2 (live `research`, Gate-B routed — explicit researchers[]: 2 evidence
   territories on jett-8081/qwen3.6-35b-a3b-q8 + 1 directive-only explorer
   jett-8012/qwen3.8-27b-fp8; 4 researchers, 7 searches, 8 cited sources, 2m34s):**
   **Decisive gap:** NO verified, OHLCV-computable "trend day" definition exists in
   public sources. Circulating rules (ORB, range > 1.5× ADR, first-hour range < 40%
   of daily range, one-sided volume, body-to-range ≥ 0.6, 10:00 close vs open, VWAP
   displacement) have no documented thresholds AND no separation statistics, and no
   cost-inclusive OOS backtest of any trend-day-gated strategy. Supporting facts:
   0DTE > 61% of SPX volume (Numerix white paper); short-gamma dealer hedging
   amplifies directional moves; low-vol environment is structural (BIS: dealer
   structured-product hedging) → range days dominate the base rate; S&P 500 futures
   show daily short-term REVERSAL (fading extremes > chasing trends; Quantpedia).
   The only evidence-backed daily classifier is the GEX regime itself (vol regime,
   not direction; options data, not OHLCV).
3. **Deliverable:** `/data/research_agent/studies/spx_vertical/` —
   `concept_brief.md` (explicitly a concept brief, not a commissioned idea):
   evidence-backed gates table + trend-day gap + 15 research directions in 4
   families — A. day classification (trend-day mechanical definition + local
   backtest = most consequential unverified lever; event calendar; time-of-day;
   seasonality/OpEx; opening gaps), B. orientation (debit vs credit beyond IV rank;
   put vs call side; skew-regime false-alarm rates), C. placement (strike vs vol
   structure; pin-level interaction — links to existing spx_0050_gamma_* and
   gamma_large_node_corridor studies; DTE; sizing), D. measurement protocol
   (baselines to beat, per-condition metrics, OOS discipline). Plus data notes
   (check research.duckdb /data/parquet scope first) and source list.
   `README.md` pointer.
4. **Committed + pushed:** `96f5824` on master of splake-cloud/research_agent —
   ONLY the 2 new files staged (tree had ~70 unrelated drifted files from other
   sessions, left untouched), Agent-Print trailer present.

## Open / next

- If commissioned: natural first study = direction A.1 (mechanical trend-day
  definitions + local backtest on SPX/ES data — the one lever with zero verified
  public evidence and direct impact on daily skip/take decisions).
- Data scoping not yet done: what SPX/ES OHLCV (intraday), VIX futures, and options
  chain data exists locally (spx_0050_gamma_* studies suggest chain snapshots exist).
- Concept brief is NOT in the idea pipeline — no study_ledger / idea gate entry.
