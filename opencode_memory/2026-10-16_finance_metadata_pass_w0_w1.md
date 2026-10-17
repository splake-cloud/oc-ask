# Finance metadata pass — wave 0 + wave 1 + wave 4 (2026-10-16)

Tagging the untagged finance rows of the paper-corpus claim bank with comparability tuples,
using the existing 10-key contract (NOT the model_tuning 11-key form). Wave 0 (plumbing) and
wave 1 (momentum + volatility + microstructure) are DONE and accepted.

## What shipped

**Wave 0 (all main-seat, no qwen-coder — PM ruling):**
- `scripts/paper_corpus/metadata_schema.py` → VOCAB_VERSION **v3** (was v2): 33 pre-seed constructs,
  6 topic seeds, gas axes (`natural_gas`/`crude_oil` underlyings; `gas_futures`/`swing_deal`/
  `storage_contract` products), `yearly` resolution, 30+ synonyms.
- `scripts/paper_corpus/validate_finance_sidecars.py` (new) — finance 10-key contract twin of
  `validate_sidecars.py` (which is model_tuning-specific). `--strict-state` enforces state files
  for NEW sidecars; legacy (15/16 equity_options) exempt. Self-test drove out 3 findings
  (mid-list `_validation` key tolerated; `yearly` missing → added; legacy state absence noted).
- `scripts/paper_corpus/canonicalize_sidecar.py` (new) — deterministic post-extraction canonicalizer.
  Idempotent (0 changes on all legacy sidecars), null-preserving, mutation-correct.
- Registry repairs: `paper_domains.json` 96→109 keys; `domain_registry.json` 12 domains coherent.
  13 papers registered: 4 momentum (already tagged), 8 natural_gas, 1 crude_oil
  (Trolle–Schwartz; Schneider–Tavin = general commodity theory tagged natural_gas, PM-overridable).
- W0 receipt: `verify/w0-finance-metadata-pass-acceptance.20261016T112551Z.txt`

**Wave 1 (22 papers / 567 rows, all sidecarred + ingested):**
- momentum_trend 9/248: jt1993, daniel_moskowitz 2016, hong_jordan_liu 52wh 2015, george_hwang 2004,
  george_hwang_li 2018, faber ATG 2024, barroso_santaclara 2015, daniel_jagannathan_kim (NBER WP 18169),
  hurst_ooi_pedersen 2017
- volatility 7/156: bollerslev GARCH 1986, kelly_jiang (NBER w19401, Aug 2013), bekaert_wu 2000,
  bollerslev_tauchen_zhou VRP 2009, brownlees_engle_kelly 2011, cont stylized facts QF 2001,
  alizadeh_brandt_diebold range-SV 2002
- microstructure 6/163: cont_kukanov OFI 2014, savor 2012, llorente 2002, campbell_grossman_wang
  QJE 1993, wang JPE 1994, easley VPIN 2011
- Pipeline per paper: qwen38-collab native sidecar mission (envelope = claims + full v3 vocab +
  10-key/17-field forms + real validator as its own `--strict-state` gate + chunked-write rule +
  identity-check clause) → main-seat verify on disk → canonicalize `--check` (all 22: **0 changes**) →
  `ingest_claims.py --replace` (metadata join on) → post-verify per-paper counts → :8090 restart →
  acceptance.
- **Coverage: 1026/4022 (25.5%) → 1593/4022 (39.6%)**
- W1 receipt: `verify/w1-finance-metadata-acceptance.<ts>.txt` (gates 22/22, canonicalize 22×0,
  live top-2 own-paper per domain: 52wh→george_hwang, vol→cont_stylized_facts, OFI→cont_kukanov 3/3,
  momentum-crash→daniel_jagannathan_kim 2/2 @9.25)

## Envelope identity corrections (agents overrode wrong envelope hints, source decided)
kelly_jiang = NBER w19401 "Tail Risk and Asset Prices" (Bryan Kelly & Hao Jiang, Aug 2013) — NOT the
2014 tail-shock paper; bollerslev_tauchen_zhou = "Expected Stock Returns and Variance Risk Premia";
campbell = "Trading Volume and Serial Correlation in Stock Returns" (QJE); wang = "A Model of
Competitive Stock Trading Volume" (JPE); cont = single-author QF 2001 (DOI verified via IOP);
daniel_jagannathan_kim = NBER WP 18169 "Tail Risk in Momentum Strategy Returns" (pre-JFE-title).
All 6 followed by agents; envelope now carries the identity-check clause as standard.

## Incidents (both caught by on-disk verification)
1. **VPIN double-write race.** Source document for `easley_lopezdeprado_ohara_vpin_2011` is an
   undated Wikipedia "VPIN" article, not the J. of Trading paper (corpus caveat; title recorded
   "VPIN", authors = the three originators, year 2011 from the cited paper). First completion
   notification arrived while the session was still running; I read a truncated transcript,
   assumed death, dispatched a retry — which then truncated the original's 26-line tags file to 9
   mid-write. The ingest (which ran during the race) still joined the FULL original file, so the
   table holds the original's verified tags (26/26 subject fill; 21 field diffs vs the retry's
   version). Recovery: reconstructed the on-disk tags file **from the table** (original tags,
   claims-file order), re-gated PASS, canonicalize 0. Disk and table now agree.
   Lesson: never re-dispatch on a suspicious notification without checking the disk AND the
   transcript tail timestamps; a retry's first write can clobber a concurrent original's output.
2. **Stale fragment handles.** Ingesting while :8090 was up → live search failed with
   `lance error: Not found: .../data/....lance` (service's in-memory fragment refs invalidated by
   the atomic swap). Fix: restart the service. Operational rule: **:8090 must be restarted after
   EVERY ingest** (the w0 flow already did; the momentum top-up broke it once).

## :8090 state
pids this session: 3356123 (w0) → 3566610 (post-micro) → **3572896 (current)**. All kills
rule-11 (pid from service + port-owner cross-check, host vantage net:[4026531833]).
Lance backups: `claims.lance.bak-w1.20261016T120545Z` (pre-copy) + tool `bak-preingest` ×4.

## Radar queue (end-of-wave vocab promotion review)
101 distinct `other:` tokens across wave 1. Top: `other:model_specification` (6),
`other:beta_exposure` (5), `other:information_asymmetry` (5), `other:model_assumption` (5),
`other:trading_volume` (5), `other:profitability_and_investment_growth` (4), `other:estimation` (4),
`other:volatility_asymmetry` (4). Promote-to-vocab candidates for waves 2–3 envelopes;
methodology-flavored tokens (model_specification/estimation) may be a tagging-guidance problem,
not a vocab gap — review before promoting.

## Wave 4 (natural_gas 8 + crude_oil 1 = 9 papers / 219 rows) — DONE 2026-10-16
- Papers: chincarini Amaranth ×2 (collapse_2008=17, no_free_lunch_2007=30), hu_hu_lin (25),
  qiu_ware_yang swing (24), rotondi gas options (28), schneider_tavin Samuelson (19), shao term-
  structure (22), till_amaranth (26), trolle_schwartz crude (28).
- **9/9 gates PASS, 9/9 canonicalize 0 changes**; single batch ingest (219 rows, per-paper counts
  exact); :8090 restarted (3572896 → **3705081**); acceptance: hu_hu_lin 2/2 @8.875, schneider_tavin
  8.875 + shao 8.25, trolle_schwartz 2/2 @9.9375; gas filters work (natural_gas 161 rows, crude_oil
  23, swing_deal 30). **Coverage 39.6% → 45.1% (1812/4022).** Receipt:
  `verify/w4-finance-metadata-gas-crude-acceptance.*`.
- **5 more identity corrections** (all envelope slugs wrong, source decided): no_free_lunch_2007 =
  "A Case Study on Risk Management: Lessons from the Collapse of Amaranth" (JAF 2008, Chincarini);
  collapse_2008 = "The Amaranth Debacle..." (JAI Winter 2007, Chincarini); hu_hu_lin = "Effect of
  Temperature Shock and Inventory Surprises on Natural Gas and Heating Oil Futures Returns" (Hindawi
  S WJ 2014, DOI 10.1155/2014/457636); shao = dated 2023 (SSRN 4575374 preprint, not 2024);
  trolle_schwartz = NBER WP 12744 Dec 2006 (working-paper version, not JFE 2009). Corpus caveat:
  gas papers' `parsed/` gate_reference files live in the staging dir
  `logs/paper_corpus/_natgas_staging_papers_index/parsed/...`, not the canonical corpus path.
- Corpus note: the two Amaranth paper_ids are distinct claim sets (0 shared claim_text) — possibly
  different versions/venues of the same case-study research; both legitimately retained.

## Wave 2 (bubbles_crashes 12 + risk_backtesting 4 + behavioral 3 = 19 papers / 478 rows) — DONE 2026-10-17
- Papers: greenwood_shleifer_you (33), phillips_wu_yu (31), johansen_sornette (30), sornette_cauwels (29),
  chen_hong_stein (28), barberis (27), brunnermeier_nagel (26), scheinkman_xiong (26), xiong_yu (24),
  abreu_brunnermeier (23), vanhemert (29), sullivan (20), magdon_ismail (18), barber_odean (28),
  hong_stein (28), li_anchors (26), phillips_yu_dating (18), bailey (23), phillips_shi_yu (11).
- **19/19 gates PASS, 19/19 canonicalize 0 changes** (after applying barber_odean's 14 `trading`→
  `other:trading` object_variable normalizations — the first time canonicalize wrote non-zero in this
  pipeline; the validator does not check object_variable vocabulary, the canonicalizer does). Single
  batch ingest (478 rows, per-paper counts exact); :8090 restarted (3705081 → **973134**);
  acceptance: LPPL → sornette_cauwels 7.06 + johansen 2×; drawdowns → vanhemert 3/3 @7.44;
  snooping → sullivan 3/3 @7.13; disagreement → xiong_yu 8.69; warrants → xiong_yu 3/3 @10.0;
  anchors → li_anchors 5.81 (behind two 52wh papers — legitimate topical overlap).
  **Coverage 45.1% → 56.9% (2290/4022).** Receipt:
  `verify/w2-finance-metadata-bubbles-risk-behavioral-acceptance.20261017T033444Z.txt`.
- **7 more identity corrections** (source decided): chen_hong_stein = NBER WP 7687 May 2000
  (not 2001); greenwood_shleifer_you = NBER WP 23191 2017 (not 2019 JFE); barberis = NBER WP 21944
  Jan 2016, authors Barberis/Greenwood/Jin/Shleifer (not 2018 AER); phillips_wu_yu = Cowles DP 1699
  2009 (not 2011 JAE); xiong_yu = NBER WP 15481 Nov 2009 (not 2011); phillips_shi_yu = Cowles DP 1914
  2013 (not 2015); magdon_ismail = "On the Maximum Drawdown of a Brownian Motion" Sept 2003 (not
  2004). Running total of identity corrections across W1+W2+W4: **18**. The filename slug's year
  is unreliable ~half the time — the identity-check clause keeps earning its place.
- bailey's source title is "Stop-outs under serial correlation and 'The Triple Penance Rule'" — the
  paper_id says triple_penance but the paper is primarily about stop-outs; title followed the source.
- Operational: `ingest_claims.py --replace` is `action=append` — one `--replace <pid>` flag per
  paper (a space-joined list is silently ignored; the dry-run shows `replace papers: []`).

## Wave 3 (technical_analysis 14 + market_structure 11) — COMPLETE 2026-10-17 — pass done
- **Scope**: 25 registry pids, `chang_osler_head_shoulders_fx_1999` dropped (0-byte claims file, 0
  table rows) → **24 papers / 1732 rows**. Exactly the remaining untagged set (4022 − 2290 = 1732).
- **Vocab v4** (bumped in `scripts/paper_corpus/metadata_schema.py`, backward-compatible — v3
  sidecars still pass the v4 validator): +22 tokens — constructs: composite_operator, supply, demand,
  volume, spread, trend_state, divergence, moving_average; regimes: accumulation, markup,
  distribution, markdown, balance, imbalance; topics: 11 (incl. value_area, point_of_control,
  primary_trend, supply_demand, climactic_action); data_sources: price_volume, tape_reading,
  market_profile, historical_charts; methodologies: discretionary, case_study, historical;
  effect_shape: regime_dependent. **Deliberately NOT applied**: ms-vocab `direction:
  bullish/bearish/neutral` — the direction axis is locked at v3 semantics (positive/negative/
  conditional/null) because 2290 existing rows use it.
- **24/24 gates PASS, 24/24 canonicalize 0 changes** (sum 1732 = scope exactly). One P1-stage
  defect: edwards_magee line 28 shipped subject "distribution" (a regime token) → main-seat
  deterministic repair to "supply" (evidence defines distribution as supply overcoming demand).
  First P1 canonicality defect across W1–W3.
- **7 identity corrections** (source decided): nelson → ©1902; cbot → ©1996; edwards_magee → 9th ed
  2007 CRC Press w/ W.H.C. Bassetti (not the 1948 original); savin_weller → WP Jan 2003 (pid keeps
  _2007); lo_mamaysky → NBER WP 7613 March 2000, WP title "…Empirical Implementation" (not the JASA
  "…Anomalies"); wyckoff_day → "The Day Trader's Bible — Or… My Secrets of Day Trading In Stocks"
  (agent rejected the envelope's alternate-title hint); wyckoff_method → ©1932 "A Course of
  Instruction in Tape Reading and Active Trading". Plus 3 year-resolutions keeping publication year
  (menkhoff_taylor JES 2007 vs WP 2006; cowles_forecasters Econometrica 1933; brown_goetzmann as
  March 1998 WP). **Running identity corrections W1+W2+W4+W3: 25.**
- **Ingest**: backup `claims.lance.bak-w3.20261017T044320Z` (41M); single batch, 24 per-pid
  `--replace` flags; dry-run: 1732 replaced, projected total 4022; real: OK. Post: table total 4022,
  W3 rows 1732, per-paper table count == sidecar count for all 24.
- **:8090** 973134 → **1156000** (python pid; nohup wrapper 1155899). Acceptance: Wyckoff
  distribution → edwards_magee 7.06 (repaired line 28 ranked #1) + pal_lstm 5.38; Dow Theory →
  brown_goetzmann 6.88 + hamilton 6.81; chart-pattern academic → dawson_steeley 5.88 + park_irwin
  5.75; market profile → dalton 7.50 + cbot 5.56; FX TA/GP → park_irwin 7.12 + neely_weller_dittmar
  6.62 + menkhoff_taylor 6.50.
- **Coverage 56.9% → 100.0% (4022/4022). FINANCE METADATA PASS COMPLETE** — 64 finance papers tagged
  across W1+W4+W2+W3 (567+219+478+1732 = 2996) + 1026 pre-W0 gamma rows.
- Receipts: `verify/w3-finance-metadata-ta-market-structure-acceptance.20261017T044632Z.txt` +
  `verify/w3-finance-metadata-coverage-gates.20261017T044655Z.txt` (verify-run, exit=0).
- Ops: tsinaslanidis first attempt died silently (8k tokens, 2 tool uses, no files) — re-dispatch
  succeeded and its agent corrected the envelope's wrong pid hint (pattern_factors →
  pattern_profitability). Two duplicate dispatches (cowles_1944, wyckoff_method) completed
  idempotently. All 24 missions ran on qwen38-collab; P1/P2 two-part protocol worked for the 4 split
  papers (edwards_magee 206+206, schabacker 113+112, hamilton 72+71, park_irwin 59+58).
- Notable subjects: schabacker chart_pattern 74 + composite_operator 69; hamilton trend_state +
  composite_operator w/ Wyckoff regimes; park_irwin trend_following_performance; williams volume +
  composite_operator; dalton other:value_area + other:auction.
- **Next (all waves done)**: end-of-pass vocab promotion review — 101+ `other:` radar tokens
  cumulative (W3 added ~17: tape_reading, professional_usage, forecast_accuracy, expert_forecast,
  genetic_programming, transaction_cost, technical_rule, bandwidth_selection, smoothing_bandwidth,
  detection_parameters, position_risk, trader_psyche, window_span, confidence_interval,
  survey_limitation, sample_bias, dow). Top promotion candidates: tape_reading, model_specification,
  beta_exposure, information_asymmetry, trading_volume, forecast_accuracy.

## Keys
- 10-key tag order: claim_id, subject_variable, object_variable, effect_shape, direction,
  timeframe{resolution,horizon}, instrument_scope{underlying,product,tenor_bucket}, regime,
  schema_version, vocab_version. `_validation` mid-row tolerated (legacy QA artifact).
- 17-field paper-level: title, authors, year, venue, doi (never invented), paper_type,
  data_period_covered, tldr, topics(3–8), methodology, data_sources, instrument_scope, evidence,
  paper_id, schema_version, vocab_version, _provenance.
- vocab_version "v3" (W1–W4) / "v4" (W3), schema_version "v1". `other:snake_case` = radar, one
  segment, [a-z0-9_-]. Validator checks tokens against the CURRENT `metadata_schema.VOCAB`
  (superset-safe across versions).
- Ingest: `ingest_claims.py --claims <paths> --replace <pid> --replace <pid> ...` (one flag per
  pid — action=append); meta_dir auto = `corpus/metadata/`; `--dry-run` = zero-write plan; back up
  `indexes/claims.lance` → `claims.lance.bak-w<N>.<ts>Z` before every ingest.
- Envelope template lives in this session's dispatches; reuse with the identity-check clause +
  the `ls`-before-PASS clause (both earned).
