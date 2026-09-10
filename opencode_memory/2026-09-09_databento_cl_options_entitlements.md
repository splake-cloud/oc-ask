# Databento GLBX.MDP3 — CL (WTI) futures + options entitlement map (verified)

Session: 2026-09-09. User reported a completed GLBX.MDP3 verification run for the Databento
account's crude-oil entitlement and asked that the access state be recorded.

## Credential location (verified on-box, value never printed)

- `DATABENTO_API_KEY` lives in `/etc/default/es_live_ingest` (also `/etc/default/nq_live_ingest`).
- `src/market_research/es_live_ingest/settings.yaml`: `api_key:` commented out; code path is
  `load_settings().api_key or os.environ.get("DATABENTO_API_KEY")`
  (`scripts/es_live_ingest/backfill_history.py:427`).
- `.env.secrets` / `.env.stack` contain NO databento key (OPENAI + MASSIVE only).
- No CL-specific ingest script exists yet — ES/NQ/SPX live ingest patterns are the templates
  (`scripts/es_live_ingest/`, `scripts/run_nq_historical_backfill.py`).

## Entitlement results (as verified by the user's run)

| Schema | Option instrument access | Notes |
|---|---|---|
| trades | ✅ historical + live | symbol-mapping received on option ids |
| mbp-1 | ✅ historical + live | live quote observed ($38.50) |
| ohlcv-1m | ✅ | |
| mbo | ❌ **Not authorized for mbo schema** | separate, denied entitlement — plan upgrade needed for L3 order flow |

- "Endpoint existence ≠ paid access": trades/mbp-1/ohlcv-1m work on option instrument_ids
  independently of CL futures access — verified, not inferred.
- MBO-dependent analyses (record counts, T/F records, aggressor side) are NOT actionable on
  options with this plan.

## Universe (GLBX.MDP3, CL options)

- 34,343 total instruments = 34,218 options + 125 CL futures (FUT, asset=CL).
- 28 option families: LO (23,486), LCE (2,368), LM1–LM5 (6,096), LO1–LO4, ML1–ML4,
  NL2–NL5, WL2–WL5, XL1–XL4, ICD (162). Not present: LO5, ML5, NL1, WL1, XL5.
- Liquid expiries by contract count: CLV6 2026-09-17 (1,164), CLZ6 2026-11-17 (1,156),
  CLX6 2026-10-15 (1,148), CLF7 2026-12-16 (818).

## Schema deviations from generic "OPT" assumptions (encode in any CL options ingest)

1. Options `security_type` = **OOF** (not OPT).
2. Outright option `leg_count` = **0** (not 1).
3. Call/Put = `instrument_class` (C/P); `secsubtype` is empty.
4. `asset` = option family code (LO, LCE, LM1…), **not CL**.
5. `market_depth` = 3 for all CL options.

## UDS combos (user_defined_instrument=Y)

- 846 UDS instruments; all have definition records resolvable by instrument_id, but
  **leg_count=0 for every UDS** — `leg_instrument_id=0`, `leg_raw_symbol=''`.
- A UDS combo **cannot be decomposed into legs from the Databento definition schema**.
  Only flag is `user_defined_instrument=YES`. Leg-level reconciliation needs a separate source.
- 3 sampled UDS: 0 trades each (far-month deep-OTM combos — expected, not an access failure).

## Underlying mapping

- 100% verified: all 33,372 outright options + 846 UDS map to valid CL futures underlyings;
  zero violations on int-cast instrument_id join.

## Byte sizes (8 ATM instruments, historical)

- trades: 0.02 MB total (~$0.00)
- mbp-1: 87.67 MB total (~$0.002)

## Open / next

- MBO access: decision pending on whether to upgrade the Databento plan for live GLBX.MDP3 MBO.
- If CL options ingest is built: reuse `scripts/es_live_ingest/` pattern; key from
  `/etc/default/es_live_ingest` env; encode the 5 schema deviations above; do NOT expect
  UDS leg decomposition from definitions.

## AMENDMENT (same day) — CL futures smoke suite (SDK 0.78, `h.timeseries.get_range`)

- **CL FUTURES MBO = ✅ AUTHORIZED** (options-only denial confirmed): CLV6 MBO 10-min window
  returned 300 records (cap). `MBOMsg ... side=A action=C`.
- **CL futures trades ✅**: CLV6 2026-09-08 = 116,438 prints / 228,144 contracts;
  aggressor side populated on ~90% (A=52,147 B=52,846 N=11,445).
- **Front month = CLV6** (nearest expiry of 11 candidates; matches user's report).
- **NO spread instruments in GLBX.MDP3**: full definition dump = 1,121,833 instruments,
  security_type SPR total = **0**. Calendar/crack "spread trades" must be SYNTHESIZED from
  leg futures. (User's Phase-1 "spread trades" premise does not exist as exchange products here.)
- `asset==CL` FUT count in dump = 4,257 (dump includes historical ladder; filter by expiration
  for currently-listed — user's "125" = current list).
- **402 account_insufficient_funds** on a 2024 MBO depth probe → account has a historical
  budget cap; MBO depth unverified; cost plan needed before bulk pulls.
- SDK 0.78 API notes: `h.timeseries.get_range(ds, start, end, symbols=, schema=, limit=)`;
  definition records: `expiration` (ns int), `contract_multiplier` (sentinel 2^31-1 on CL),
  `min_price_increment`; MBP1Msg py field names ≠ `bid_price` (use SDK pretty_ accessors);
  `symbology.resolve` exists for symbol→id maps.
- Phase-1 feasibility study (CL order-flow anomaly detection pre-news) designed; verdict
  conditional-YES pending budget + MBO depth confirmation.

## COST / BUDGET — CORRECTED (user ruling 2026-09-09)

- **NO top-up needed for the 12-month CL pilot.** User-confirmed: the account already
  covers it. Reconciliation: every 402 I hit was on an **MBO** request (2024 depth probe,
  12-mo MBO batch). The pilot does NOT use MBO — it runs on CL options trades + MBP-1
  (large prints, same-strike/expiry accumulation, side/aggression, cross-strike/expiry
  sweeps, C/P concentration, premium + delta-equivalent exposure) + the CL futures ladder
  (trades + MBP-1) for coordination. All of those pulled cleanly with no billing error.
- The 402 is a per-request budget check on estimated cost (uncapped/long MBO windows trip it);
  it is NOT an entitlement denial (that's `Not authorized for <schema>`, which only options
  MBO produced) and is moot for the pilot.
- Data-size reference (derivation, not a metered quote): 12-mo options trades+MBP-1 full
  universe + 15-contract futures ladder ≈ low-hundreds of GB at worst; CLV6 trades measured
  116,438 prints/day. Anchor: user's mbp-1 datapoint 87.67 MB ≈ $0.002 (~$23/GB).

## ACCIDENTAL JOBS (same day) — still open

- **Dry-run trap:** `POST {gateway}/batch.submit_job?dry_run=true` is IGNORED on this
  account's gateway (`https://hist.databento.com/v0/batch`) — it CREATED real jobs.
  4 jobs left queued/processing (delete endpoint 404 on v0; cancel via portal/support):
  `GLBX-20260909-PTV5YCFAEX` (mbp-1, 15 CL syms, 12mo), `GLBX-20260909-EYCHNNS5MD` (trades),
  `GLBX-20260909-9RRYHV3YX3` (mbp-1), `GLBX-20260909-6QBA4VEQSD` (trades). If they complete,
  output = pilot's futures-ladder trades+mbp-1 (usable, not wasted; pair is duplicated).
