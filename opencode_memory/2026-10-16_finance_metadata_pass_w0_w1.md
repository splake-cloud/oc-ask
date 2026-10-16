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

## Remaining waves (approved scope)
- **W2**: bubbles_crashes 12/306 + risk_backtesting 4/90 + behavioral 3/82 (vocab mostly fits)
- **W3**: technical_analysis 13/1016 + market_structure 11/716 (biggest vocab gap; apply + extend
  existing `vocab/market_structure.json`; big papers split 2-part: edwards_magee 412, schabacker 225,
  hamilton 143, park_irwin 117)
Target after all waves: 4022/4022 (100%). Current: 1812/4022 (45.1%).

## Keys
- 10-key tag order: claim_id, subject_variable, object_variable, effect_shape, direction,
  timeframe{resolution,horizon}, instrument_scope{underlying,product,tenor_bucket}, regime,
  schema_version, vocab_version. `_validation` mid-row tolerated (legacy QA artifact).
- 17-field paper-level: title, authors, year, venue, doi (never invented), paper_type,
  data_period_covered, tldr, topics(3–8), methodology, data_sources, instrument_scope, evidence,
  paper_id, schema_version, vocab_version, _provenance.
- vocab_version "v3", schema_version "v1". `other:snake_case` = radar, one segment, [a-z0-9_-].
- Ingest: `ingest_claims.py --claims <paths> --replace <pids>`; meta_dir auto =
  `corpus/metadata/`; `--dry-run` = zero-write plan.
- Envelope template lives in this session's dispatches; reuse with the identity-check clause +
  the `ls`-before-PASS clause (both earned).
