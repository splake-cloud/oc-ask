# 2026-09-17 — gamma_node_price_pull_discovery: Forward Validation Protocol v1 FROZEN + logger armed + v1.1 opening cohort

## What was built/decided

Research Agent study `gamma_node_price_pull_discovery` (A-1 extension;
upstream: blueprint v3.3 ratified, A-1 build C0–C6 complete, JOINT D1 =
INDETERMINATE). This session took the study from "build complete" to
"forward validation protocol frozen + logger armed + accrual live".

1. **PM two-hypothesis ruling → two-gate architecture.** The forward gate
   separates: RESEARCH GATE (does node-side distance closure beat the matched
   no-node control — C1′ for NEG cells, ΔFWD incremental drift for POS cells,
   floor 5.0) from TRADING GATE (does the actual signed SPX/ES move go in the
   proposed direction — ≥ 3.0 pts/60 min, day-block CI > 0, both calendar
   halves > 0, ES executable agreement). Cell TRADEABLE = both gates + all
   conjuncts; arm-level TRADEABLE = both cells. This exists because the
   corrected retrospective exposed NEG-above as C1′-positive but node-side
   flat (control-driven) — the contrast alone must not be sold as a
   directional edge.
2. **Protocol v1 FROZEN (2026-09-17, PM-ratified with amendment).** H1 NEG
   attraction (both side cells, trade toward K\*), H2 POS bullish drift (both
   positions, long, over no-node benchmark); POS approach/flight pattern kept
   as cell-level evidence only, never a common-magnetism claim. Amendment:
   two separately declared m=4 families (research, trading), each
   Benjamini–Hochberg q < 0.10, corrected separately, never pooled.
   Support-bound gate: 20 independent setup-days per verdict cell; window
   open until support accrues or **2027-09-16**, no automatic extension.
   Stage-2 diagnostic-only + refreeze clock-restart clause. No-peeking:
   single terminal read; support ledger is the only monitorable quantity.
   §8 executable capture: ES prices, SPX 0DTE quotes/spreads, feed latency,
   signal/exit timestamps.
3. **Logger armed** (`scripts/forward_logger.py`). Setup detection mirrors
   the frozen predicate verbatim (T0L, r30, window, first-capture anchor);
   §8 capture end-to-end with zero nulls. **Smoke caught a real defect:**
   the first draft applied gates before the anchor; A-1/F-R3-1 requires the
   anchor (first large-S6 capture per (day, K\*, arm)) first, gates AT the
   anchor. Fixed; predicate fidelity then 12/12 key-identical to the
   committed A-1 episode set (incl. ODD exclusion, zero-setup, multi-setup
   days).
4. **Gamma capture incident sequence (PM-stated).** UW gamma substrate =
   same-day EOD capture (NOT an ingestion lag — initial receipt wording
   corrected). Collector machine down for maintenance after 2026-09-14;
   back-fill Friday 2026-09-18, then normal schedule. **Additional gap
   found: 2026-09-07 has no capture in ANY source** (raw feed, pool-level,
   certified pin) — independent of the outage; NO_DATA logged; vendor
   re-ingest question queued for Friday.
5. **v1.1 ruling (PM): no days lost to documentation boundaries.** Forward
   COLLECTION start = 2026-09-02 (first gamma-covered session after the
   frozen 180-day slice). Opening cohort 2026-09-02 → 09-14 logged from the
   designated substrate source: 8 setup-days (neg-above 2, neg-below 2,
   pos-above 1, pos-below 4). Protocol resealed; nothing else in the freeze
   touched; A-1 completed-study results immutable (frozen population +
   C2 pool-wide matching makes "A-1 + more days" technically
   non-incremental as well as governance-forbidden).

## Key facts (paths under
`/data/research_agent/studies/gamma_node_price_pull_discovery/`)

- `specs/forward_validation_protocol.md` — FROZEN v1 + v1.1. v1 sha
  `e5a0752b05bfd58bb68bf6e9ef9c07cb36c22eb986178b452259d64978b7e373`; v1.1
  sha `72323f84c0f5cb06ead7b654be642a4fc50c16cbc5adc2c4d20543045c264b12`.
- `receipts/forward_protocol_v1_seal.md` (v1 + v1.1 seals),
  `receipts/forward_logger_arm_2026-09-17.md` (source provenance, declared
  deviations, Friday checklist).
- `scripts/forward_logger.py` — `replay --date D [--gamma PATH]` /
  `ledger`. Gamma source = designated UW substrate
  (`/data/agentic_trading/pools/uw_gamma/uw_per_strike.parquet` build);
  SPX 1-min `/data/parquet/spx_1min`; ES front
  `/data/parquet/es_1min_front` (OHLC only — declared proxy, no bid/ask);
  SPX 0DTE `/data/parquet/spx_intraday_strikes` (HHMM-encoded snapshots).
- `outputs/forward/support_ledger.csv` (live: 8 setup-days),
  `data_quality.csv` (09-07 vendor gap; 09-15/16/17 outage, back-fill
  pending), `daily/<date>.parquet` (raw §8 quantities only — no gate
  statistics by construction).
- **Declared deviations (bind on the terminal memo):** ES = OHLC proxy
  (spread/slippage netted in Stage 4); C2 control on forward days computed
  at the terminal read (day-pool 1:1 greedy, not per-setup); replay feed
  latency synthetic 0.0; forward-day r30_bps NULL (covariate, not gate).
- **Provenance:** corrected 189-pair side decomposition (an earlier
  contaminated probe — arm key dropped in a merge — is voided in-document):
  NEG-above C1′ +5.91 (node-side M60 −0.41 flat → control-driven),
  NEG-below +7.28, POS-above +7.03 (fwd −0.77), POS-below −9.62 (fwd
  +1.65). NEG OOS day-weighted +7.82 falls to ≈ +3.0 excluding the two best
  days — heavy-tailed, top-loaded.
- research_agent commits (all pushed, master): `1a57a7c` (freeze + arm),
  `41c5e31` (outage correction), `0247a28` (maintenance resolution),
  `fed0bfa` (v1.1 + opening cohort).

## Next steps

- **Friday 2026-09-18:** verify back-fill on disk → replay 09-15/16/17
  (09-17 = first pure-forward session; 09-15/16 = pre-freeze provenance
  only, never forward support); ask vendor whether 09-07 can be re-ingested;
  then normal same-day EOD runs (`replay` after each session's capture).
- Expected support: binding cell NEG-below ≈ 3.1 setup-days/month → ~March
  2027 at observed incidence; **no interim outcome reads** (single terminal
  read by design).
- A-1 final adjudication (`prompts/adjudicator.md`) still awaiting PM
  initiation — separate from the forward work.
