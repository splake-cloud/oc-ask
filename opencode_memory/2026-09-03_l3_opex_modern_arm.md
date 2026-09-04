# 2026-09-03 — L3 OPEX gamma: modern-arm A0 build (the "second shutdown")

**Context:** user said the opex strategy had "shut down abruptly" twice. Found: study =
`/data/agentic_trading/studies/opex_week_l3/` (OPEX weekly gamma, spec v1 ratified
2026-08-11). Historical arm (2013-21, SRC-A) + settlement extension to 2026-09-02 (G0c
anchor) were DONE. Stuck task = modern arm A0 build
(`scripts/opex_l3_modern_arm_data.py`, SRC-B 2022→).

## What was actually killing it
- A detached `pi` child of zombie session **2047423** (pts/5, idle TUI, Sept 1) sat in a
  retry loop re-firing the build every ~10 min; the script had a fatal `itertuples` bug in
  `write_report` → crash every cycle → "abrupt shutdowns".
- Killed the loop + its in-flight run. It **respawned twice more** (children 2945833 @01:08,
  3026108 @02:41); the second generation wrote a competing `build_a0_modern.py` +
  `fix_f8.py` into `outputs/modern_arm/` and **clobbered the canonical CSVs mid-verification**.
  Escalated: killed the whole 2047423 tree (~03:43). Competitor artifacts quarantined in
  `.ai/staging/l3_modern_arm_edit/competitor_artifacts/` (its build had the SAME S0 bug).

## Frozen L2 derivation (pinned from source, per AGENTS.md doctrine)
Per-week: E = last trading day Mon–Fri of the week; is_opex via `pattern_opex_week`
per-date flag; settlement S (OPEX, third-Friday E) / W (non-OPEX) at E from
`studies/opex_week_l2_iv/data/settlements_spx.csv` (sha 12d4c3ad…, G0c-anchored to
.bak_2013_2025 byte-for-byte); coded-expiry root join {E, E+1, E+2}; S0 at T0 on the A0
clock; find_atm_strike dual semantics (mode of min |strike−S0| among IV-valid rows).

## The real bug (G1 caught it)
A0's S0 used SRC-B `stockPrice` (ported blind from SRC-A) — but in SRC-B **stockPrice is
per-row, NOT the index level** (37-56 distinct values/snapshot). Correct column =
`spotPrice` (1 unique value/snapshot, tracks official SPX close). Wrong column → S0 off
5-13pts → ATM K flips vs L2b → G1 (A0 16:00 vs L2b SRC-A EOD, spec: ≤5bp or per-week
report) failed at 10-100bp. Fixed round 3: `S0 = float(snap_df["spotPrice"].iloc[0])`.

## Delegation (no task tool on this seat — used `pi --print --no-session`)
Model `jett-8081/qwen3.6-35b-a3b-q8`, cwd=/data/agentic_trading, envelope in
`.ai/staging/l3_modern_arm_edit/`. Rounds: r1 build (8 defects found on review → bounce),
r2 fixes (sha 90fc5855), r3 S0 fix (sha **d1441a6a** = current). Round-1 pre-dispatch
pre-test: G0c pandas re-serialization of ≤2025-12-31 rows byte-identical to .bak.

## Verified final state (script sha d1441a6a; transcripts verify/l3-a0-modern-run{1..5}.)
- **Determinism: PROVEN** — run#4 vs run#5 (independent, same script, same data window)
  byte-identical on all 5 CSVs: a0_eod ba03d5bb, eod_family 62ffda54, a0_open 5e8e33e0,
  open_family 9f580ff5, state_features f7d78ec4 (state_features also == run#3 → S0 fix was
  surgical, features untouched).
- Population: 244 Mondays 2022-01-03→2026-08-31; 55 OPEX / 189 non-OPEX (calendar ends
  2026-07-17 → Aug/Sep-2026 misclassified non-OPEX, documented).
- EOD: 212 COMPLETE / 32 INCOMPLETE = 25 holiday T0s + 1 vendor feed gap (2022-01-17, the
  FIRST OPEX week of 2022 — file absent) + 2 no-1600 + 4 missing W settlements
  (2026-01-30/02-27/07-31/08-21, feed-side gap).
- G0: PASSED. G1: 89/204 members within 5bp, max 67.1bp; residual = final-seconds index
  move (vendor 16:00 spot vs official close flips ATM K; e.g. 2020-08-31: 10.5pts) +
  vendor-vs-official quote. Per-week detail + two-part explanation in receipts/a0_g1.md
  (spec fallback). A0 = primary; "L2b-equivalent" holds for clock design, not per-week values.
- Family (A0 rule): **NONE ×3 both clocks** (EOD: val −10.9bp CI[−51.5,+31.8] p=.66, long
  −10.8bp p=.66, short +10.7bp; Holm 1.0; n=50/162; era splits 2022-24/2025+/2026-YTD
  context-only). Robust pre/post S0 fix.
- Spot-checks hand-verified: 2022-01-03 non-OPEX E=01-07 S_T=4677.03 (W ✓ settlement feed);
  2022-06-13 OPEX E=06-17 S_T=3663.76 (S ✓); pnl recompute byte-exact.
- F8 non-null 64/244 (NULL-gamma NaN propagation per frozen hist spec; competitor fillna(0)
  rejected as spec deviation).

## Block B COMPLETE (this session, 2026-09-03, commit 4d9e5e17)
The state-conditioned search over the A0 maps — the piece this card flagged as the stuck item.

- **F8 NULL fix (T1 primary, PM-ruled):** the delegate's T3-recompute primary was rejected — 68% of
  NULL-gamma rows are degenerate (callMidIv 0.0 or ≥10.0), so a d2CS/d2S recompute is unvalidated on
  exactly the population it must cover. Ruling: T1 = missing-row exclusion with a coverage gate
  (`na_null_oi_share = |m|≤5% OI on NULL rows / |m|≤5% total OI ≤ 1%`); T3 only as a bounded
  sensitivity on the gated weeks. Result: **201/215 weeks COMPLETE, 14 INCOMPLETE** (na_null_oi_share
  1.3%–24.6%); 328k degenerate rows excluded (96.5% in the |m|>4% OTM tail, γ→0); NULLs are a 2022+
  SRC-B artifact (2020-21 SRC-A overlap has ZERO NULLs); SRC-A↔SRC-B F8 sign-agree 87% but magnitude is
  3-5× smaller in SRC-B (cross-vendor quote gap, NOT sign-flipping) — so cross-era F8 magnitudes are
  NOT directly comparable. T3 sensitivity (gated weeks): MAE 0.00016–0.0006, 19–54% within 25%, ~54% of
  imputed rows in the worst week used the put-IV fallback (documented caveat). Non-F8 columns
  byte-identical (SHA-256 proof); determinism clean.
- **F9 build (UW net-gamma sensitivity, 09:30ET, TZ-aware):** NET=SUM(gamma); 35 weeks have data
  (lake starts 2025-12-12); **7 OPEX + 1 holiday (2026-02-16, Presidents' Day) + 1 no-pnl (2026-08-17,
  calendar misclassification)**. The delegate initially mislabeled the Feb-2026 OPEX T0 as 2026-02-09
  (a non-OPEX week); caught + fixed (2026-02-16 → UNAVAILABLE_T0_HOLIDAY). F9 OPEX values −5437…+3888
  shares, sign-mixed; pnl −0.0075…+0.018.
- **G_B0 (outcome-blind, deposited+SHA-256-hashed BEFORE the search):** 94 binned cells (27 features ×
  quartile/pin/sign splits) → **13 SEARCHABLE** (n_OPEX≥20 AND n_nonOPEX≥20 within bin). Fewer than the
  hist arm's 35/98 — expected at 212 vs 469 weeks.
- **Holm (13 cells × 3 members {pnl_val,pnl_long_exec,pnl_short_exec} × 2 clocks {EOD,opening} = 78;
  month-clustered bootstrap 10k SEED=42; 10bp floor; frozen verdict logic cleared_floor =
  |diff|≥10bp AND CI-excludes-0):** **0 CLEARS_FLOOR / 0 MARGINAL / 78 NONE.** 31 cells hit 10bp
  magnitude but **0 have a CI excluding 0** (min raw_p = 0.55). This is a STRONGER null than the hist
  arm (which had 25 MARGINAL). Verified: diff recompute exact (F1_fc_OI high × pnl_val × EOD =
  0.000429, n=29/23), family structure matches the hist-arm template, G_B0 deposit precedes search,
  determinism byte-identical.
- **L3 VERDICT (both arms, era-stable):** NO OI/gamma/auction state identifies an executable OPEX
  subset after Holm — 0 CLEARS_FLOOR in 2013-21 (SRC-A) AND 2022-26 (SRC-B). The OPEX-week state
  search is exhausted; the remaining lever is the L2b mispricing signal itself (a different study).
- **Commit 4d9e5e17** (29 files: scripts/, outputs/modern_arm/, data/). Modern arm fully tracked.

## L3-UW limited-N study (the primary UW-gamma study, FINALLY TESTED) — commit e4c33a1d
PM ruled (2026-09-03): (1) the G_B0 n>=20 gate was a large-search device, misapplied to F9 — it
auto-precluded the very study ordered; (2) two material data defects: calendar ends 2026-07 (2026-08-21
OPEX mislabeled non-OPEX, PnL uncomputed) + outcome used callValue not the executable short-straddle-at-bid.
Rebuilt as a limited-N study (scripts/opex_l3_uw_limitedN.py, outputs/uw_arm/):
- **N=9 OPEX weeks** (recovered 2026-06-18 [was dropped] + 2026-08-21 [was mislabeled]; holiday week
  2026-02-20 uses FIRST trading session 2026-02-17, which has UW+SRC-B). Decision 9:30ET; OPEX =
  "E has an S settlement" (settlement file, NOT the read-only calendar).
- **Executable short-straddle-at-bid outcome** = pnl_short_exec = ((callBid+putBid)-|S_T-K|)/S0 (the
  A0 definition, previously never tested vs F9); S_T=official S. 8/9 weeks clear the 10bp floor.
- **3 UW features** (SRC-D 9:30ET; side==sign(gamma)): net_gamma=SUM(gamma); normalized_gamma_balance=
  net/SUM|gamma|; gamma_sign=sign(net).
- **Exact inference** (NO n>=20 gate, NO Holm, NO asymptotic p): 9! permutation on Spearman; Fisher on
  sign. Matched controls (outcome-blind, S0+month nearest).
- **VERDICT: NONE (limited-N) for all 3.** net_gamma rho=+0.117 exact p=0.776 (I re-enumerated 9!=362880
  independently: 0.775628 exact match); balance rho=+0.300 p=0.437; gamma_sign Fisher table [[3,2],[2,2]]
  p~0.99 (I computed 0.992). LOO 0/9 sig; best-week-removed rho=0. Not robust.
- **Suggestive only: 125bp gamma_sign-group gap** (+1 weeks mean +42bp n=5, -1 weeks mean -83bp n=4).
  Directionally sensible (long gamma = dealers hedge = suppressed moves = short straddle profits) but
  driven by ONE outlier (2026-04-17, short-gamma, -345bp, +288pt move) -> fragile, NOT a finding. Candidate
  for prospective frozen-hypothesis tracking, not a tradeable edge.
- Matched controls: OPEX not systematically different (mean diff -63bp, sign test p=1.0).
- Verified: raw-byte pnl recompute exact (2026-08-21 -0.00382394, 2026-04-17 -0.03454865); net_gamma
  recompute exact; 9! permutation exact; controls non-OPEX + outcome-blind; determinism byte-identical.

**L3 FINAL: the ORATS/OI state search (hist + modern) AND the primary UW gamma study are both null.**
No OI/gamma/auction/UW state identifies an executable profitable OPEX short-expiring-straddle, 2013-2026.

## Canonical UW gamma substrate v1 — CERTIFIED (PM ruling 2026-09-03, commit e9c6912b)
Built to be the frozen, validated base for all future UW-gamma studies. `studies/opex_week_l3/uw_gamma_substrate/`:
- raw_file_manifest (360 files, sha256) + uw_per_strike.parquet (1,587,919 rows; signed dealer gamma AS-SUPPLIED,
  gamma_is_null, side, DST-correct capture_ts_et, spot, provenance) + uw_snapshot_gamma.parquet (7,261 snaps;
  net/gross/balance/pos/neg/concentration/decision-snapshot) + uw_opex_coverage.parquet (9 weeks) +
  accepted_rejected_snapshots.csv (7,194 acc / 67 rej) + validation_report.md (10 gates).
- **10 certification gates:** 1-6,8,10 clean (sign integrity 0 mismatches, aggregation recon 0.0 exact via
  independent path, DST flip 03-06→03-09, 9/9 OPEX). Named findings: 4 schedule-gap dates; 58 off-schedule
  20:00Z captures (rejected); 9 all-null snapshots (696 nulls 2026-01-15 preserved as NaN); 18 continuity
  flags; **spot_close NULL all 46 dates 2026-06-16..2026-09-01 (1,978 snaps, gate-9c) → spot only thru 2026-06-15,
  gamma complete full window**. Gate 9 is cross-view (raw Periscope JSON not on box).
- **PM CERTIFIED v1 for research use** (2026-09-03). Coverage limited but complete for the 9 available OPEX weeks.
- **Cross-validated:** substrate OPEX decision net_gamma == the limited-N study's net_gamma, 9/9 exact.
- **L3 FINAL: the limited-N null stands, now resting on a validated substrate.** Broad ORATS/OI search null
  (hist+modern); primary UW gamma study null (limited-N); the substrate is the certified base for any future
  UW-gamma work (longer window as the lake accrues data, spot gap closes, or new features).

## Open / next (PM-owned)
0. **COORDINATION FAILURE (PM-flagged 2026-09-03):** the start instruction was that the two
   agents coordinate on the A0 piece; it did NOT happen. Two pi sessions were concurrently on
   L3 OPEX: THIS seat (pi 01a064c7, Pi tmux) and 01a05e20 (the SML/SAL session, Pi_2 tmux,
   resumed ~09:25, working "envelope-2: F8 fix + Block B search + F9 UW" as of 12:44).
   **Ownership split effective on PM instruction:** gamma/L3 OPEX hardening = single agent
   (01a05e20) under PM hand-supervision. THIS session steps back from all L3 OPEX artifacts
   (scripts/, outputs/modern_arm/, receipts) to avoid clobbering; do not re-enter without PM go.
1. ~~Modern Block B search~~ **DONE (commit 4d9e5e17):** F1-F8 state search (13 searchable cells ×
   3 members × 2 clocks, Holm) = 0 CLEARS_FLOOR / 0 MARGINAL / 78 NONE; F9 THIN/descriptive (7 OPEX).
   Both arms now 0 CLEARS_FLOOR — the L3 state search is closed.
2. Caveat for anything using L2b as reference vs A0: cross-source deviation profile above.
3. 2026-09-01 week (anchor Mon 2026-08-31, E=09-04 W) already in map; 2026-09-25 OPEX week
   (S=4703.42 present) enters as the week's data lands. Rebuild = same script, ~15-75 min
   depending on host load.

## Canonical UW gamma substrate (certified, frozen) — commit e9c6912b
PM ordered a clean certified substrate for all future UW-gamma studies (no OI reweight / ORATS /
imputation / BVC; gamma AS-SUPPLIED). Built under studies/opex_week_l3/uw_gamma_substrate/ (14 files).
- raw_file_manifest.csv (360 files, 360 unique sha256) · uw_per_strike.parquet (1,587,919 rows;
  capture_ts_et DST-corrected, gamma_is_null, side, sign_agrees, spot, source_row) ·
  uw_snapshot_gamma.parquet (7,261 snaps; net/gross/normalized-balance/pos/neg/null/concentration/
  decision-snapshot flag) · uw_opex_coverage.parquet (9 weeks) · accepted_rejected_snapshots.csv ·
  validation_report.md (10 gates).
- 10 gates: counts+sampled rows+recon diffs+NAMED FAILURES. Gates 1-6,8,10 clean. Named findings:
  4 schedule-gap dates; 58 off-schedule 20:00Z captures (rejected); 9 all-null snapshots (2026-01-15
  696 nulls preserved as NaN); **spot_close NULL all 46 dates 2026-06-16..2026-09-01 (1,978 snaps,
  gate-9c)**; 18 continuity flags. 7,194 accepted / 67 rejected.
- Verified independently: OPEX decision net_gamma 9/9 EXACT match vs the limited-N study; DST
  winter -05/summer -04 (boundary flip 03-06->03-09); all-null snap -> NaN rejected; 1,587,919 rows;
  sign_agrees all True; net/gross recon 0.0 (independent path); byte-identical determinism.
- Raw Periscope JSON NOT on box -> gate 9 is cross-view (profile_bars vs snapshots), documented.
- IMPLICATION: spot-based work needs data through 2026-06-15 only; gamma is available full-window.
