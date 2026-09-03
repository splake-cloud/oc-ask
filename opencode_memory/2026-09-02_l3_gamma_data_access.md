# 2026-09-02 — L3 OPEX gamma study: data-access diligence + scope

**Thread:** gamma (L3/UW) study data-access scope (follows the TC SML fly work).
RAG-grounded, then verified on the actual bytes (bounded read-only probes).

## What I did
Data-access profile diligence on the L3 OPEX gamma study (`studies/opex_week_l3/`):
RAG for the contracts (the design_ruling.md PM ruling + technical_spec_v1.md r4 pre-registered
spec were already on the box — I read both), then bounded probes of all 5 sources to verify
what's actually runnable. Wrote the verified scope:
`studies/opex_week_l3/data_access_scope.md` (agentic_trading commit 289117e1).

## The 5 sources (all verified on-box)
- **SRC-A spx_daily_strikes** (EOD, 2006-2022): the historical arm. 2013-12-20 + 2019-12-20
  OPEX days fully populated (gamma nonzero 1737/6691, OI, volume, spot). Chain grew by era
  (2013: 229 strikes/17 exp; 2019: 337/40).
- **SRC-B spx_intraday_strikes** (intraday, 2020-2026 LIVE): modern arm + A0 outcome prices.
  2025-12-19 OPEX: 09:35+16:00 snapshots, 451 0DTE strikes, OI present + stable all session
  (C2 daily-published state confirmed), liquid quotes.
- **SRC-C gamma_substrate** (BVC, 2022-2026): net_gamma_oi, dealer_sign, skew_25d, term_slope,
  vanna/charm, dist metrics. Labeled sensitivity only (F8b), 2022→ only.
- **SRC-D gamma_intraday** (UW Periscope, **2025-12-12 → 2026-09-01**, 180 days): the F9 tier-1
  source. gamma_profile_bars = per (snapshot×strike) signed gamma + vanna + charm, 252 strikes,
  10-min captures (36 winter / 42-43 summer). NET=SUM(gamma) varies (min -25830, max 998, all
  nonzero). **Only 8 OPEX expirations** (2025-12-19 → 2026-08-21) = the small-n modern arm.
- **SRC-E settlements_spx.csv** (CBOE S+W): **FROZEN at 2013-01-04 → 2021-12-31** (107 S, 1009 W).
  2022+ ABSENT.

## Key findings (the scope)
1. **Settlement gap = the ONE hard blocker for the modern arm.** SRC-E frozen at 2021. The
   modern outcome (A0, 2022+) + the entire UW arm (2025-12+) need 2022→present settlements.
   Requires extending `scripts/opex_l2_settlement_ingest.py` (CBOE public HTTPS, no auth) — but
   `YEARS = range(2013, 2022)` is HARDCODED, so: widen YEARS to 2013→2027 + smoke-test the 2022+
   format + make the write append-only (byte-identical G0c). Network-dependent BUILD step.
2. **ET-offset correction:** the RAG card says "ET = UTC-4 (2025-12)" — **WRONG**. Verified
   time-zone-aware: winter = EST (UTC-5, captures 14:00Z→19:50Z = 09:00→14:50 ET), summer = EDT
   (UTC-4, 13:00Z→19:50Z = 09:00→15:50 ET). The F9 09:30ET decision-time capture = **14:30Z
   winter / 13:30Z summer** — must be computed per-date, never a fixed UTC minute.
3. **F9 small-n:** 8 OPEX weeks (report actual n, never suppress — per the ruling).
4. **Historical arm (2013-21, ~108 OPEX weeks) is runnable NOW** — full F1-F8 from SRC-A,
   F10 (SRC-B 2020-08+), outcome = frozen L2b per-week PnLs (already computed). No network,
   no A0 needed. This is the workhorse (where G_B0 n_OPEX≥20 + Holm have power).
5. **Modern arm (2022+; UW 2025-12+) BLOCKED on the settlement extension.** After it: A0
   outcome map + F9 (8 OPEX weeks) + F1-F8 (SRC-B).
6. G0 gates (OI effective-date convention ≥3 dates vs OCC, OI availability, byte-repro, dual-
   series 2021 exclusions, root selection) are NOT yet run — they run during the build.

## Execution order (scope)
1. Historical arm (now, no network) → 2. Settlement extension (network, PM go) →
   3. Modern arm (A0 + F9). G0-G4 gates at each stage.

## Standing caveats (ruling/spec, must carry into any L3 claim)
Gamma/OI = conditioning variables, never causes. No signed-gamma causal claims. OI ≠ flow; OI
+ OI-weighted features = opening-inventory prior (tier 3, not live book). Raw gamma/turnover =
pricing-surface state (tier 2), NOT positioning. "gamma / net gamma / gamma profile" (not "GEX").
2012 excluded. No cell-level claim outside the closed per-arm Holm family.

## Open / next
- PM decision on execution order: run the historical arm now (no network), and/or approve the
  settlement extension (network) to unblock the modern arm.
- The gamma study BUILD (Block B historical arm) is the next step once PM picks the order.

## Follow-up (PM approved both): execution results

**(b) Settlement extension (unblocks modern/UW arm) — DONE** (delegated qwen38-collab, commits c227ec7a + 81bbb0a5):
- settlements_spx.csv now 2013-2026 (2248 rows; 2013-2025 G0c byte-identical + 160 2026 rows).
- All 8 UW OPEX weeks' S_T present: 2025-12-19=6796.54 + 2026 {01-16:6960.38, 02-20:6840.59, 03-20:6594.63, 04-17:7085.86, 05-15:7439.67, 07-17:7441.18, 08-21:7687.93}.
- 2 bounces: (1) off-by-one (range ended at 2025); (2) re-run dropped 44 W-fill rows + hit read-only pattern_opex_week certification (ends 2026-07-17) + fill-file-span. Fixed via the robust path (restore verified 2013-2025 + append 2026 from the already-fetched raw/S_2026.json + raw/W_2026.json via the script's own parse_new). Documented: 2026-08-21 (future OPEX) can't be cross-certified (read-only calendar); S=8 for 2026 is temporal (Sep-Dec not settled).

**(a) Historical arm (2013-21) Block B — DONE** (delegated qwen-coder, commit 83821977):
- F1-F8 built on the expiring root (469 weeks; F5-F8 coverage 435/469 = near-ATM gate drops ~34 sparse weeks). F10 descriptive, not built (excluded per C8).
- G_B0 outcome-blind support gate (deposited BEFORE any PnL access — verified line-order in blockb.py): 98 cells -> 35 searchable (n_OPEX>=20 & n_nonOPEX>=20).
- Holm family = 35 cells x 3 members (pnl_val/long_exec/short_exec) = 105, month-clustered bootstrap 10k SEED=42, 10bp floor.
- **VERDICT: CLEARS_FLOOR=0, MARGINAL=25, NONE=80.** No OI/gamma/auction state identifies an executable OPEX subset after multiplicity. MARGINAL cluster: low full-chain OI / low OI concentration -> cheaper straddle long-exec (CI excludes 0, Holm p=1.0).
- Verified: G_B0 ordering, determinism (byte-identical re-run), hand F7+F8 spot-checks (2015-02-17 OPEX + 2013-01-07 non-OPEX). F8 = expiring-root CP_FIXED_OI (defensible interpretation; spec silent on expiration window).

**Next:** modern arm (A0 outcome map + F9 UW search on the 8 OPEX weeks) is now unblocked. NOTE: a concurrent A0 process (scripts/opex_l3_a0_outcomes.py + studies/opex_week_l3/data/) was already active when I ran — coordinate before building the modern arm to avoid duplicate work / concurrent-commit clobber.
