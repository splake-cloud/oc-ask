# 2026-09-02 — TC "Strongest Morning Line" as a conditional signal for the SPX 0DTE put-fly

Topic: does the Discord channel author's **SML (Strongest Morning Line)** / **SAL (Strongest Afternoon Line)**
carry edge for the desk's SPX 0DTE long-put butterfly, as the *third* condition on top of the convergence
decision tree (Regime 3/4 → premium ≤28% → **SML side**)? Plus a re-derivation of the "gold cell" peel/runner.

## Constraints (stated once — professional desk, don't re-qualify small-n every message)
- **Fill data excluded** — ORATS bid/ask worst-fill is too conservative; ALL analysis on **mid** marking.
  CBOE fill data can be bought but is moderate value for fine-tuning; **n is the binding constraint, not fills.**
- **ES is the live anchor** (author quotes it in real-time); **SPX is a hand-waved estimate** from the ES-SPX
  spread. The fly test is against **SPX**, so repaired rows snap SPX to the true `spx_1min` index level.
- **SML is a MAGNET** (price migrates toward it), NOT "support" (floor). This made proximity-to-body the WRONG
  test shape; **direction (above/below body)** is the right signal.
- SML joined **by day regardless of print time**; print time recorded as metadata, never used to drop rows.

## Data built
- `data/discord/strongest_lines.parquet` — **600 rows** (336 SML, 263 SAL, 1 GENERIC) from the
  VolSignals.com Discord export (`~/discord-export`, 6,194 msgs / 586 attachments). 2025-02-13→2026-09-01 (326 days).
- Schema: `date, time, ts_utc, kind, es, spx, spx_index, basis, es_source, spx_source, repaired, data_flag, seq_of_day, message_id, author_name`.
- Repairs: 14 missing SPX backfilled from `spx_1min` (index-to-index); 9 ES digit-garbles fixed; 16 SPX snapped
  to true index. Final flags: clean=574, wide_basis=23, line_below_spot=3.
- **Do NOT use `es_continuous_databento close − cumulative_offset` as ES ground truth** — ~50-70pts off on a
  subset (roll-seam artifact); ES data ends 2026-08-31. `es_tpo_profile` is on the offset-adjusted scale.

## THE FINDING — SML *direction* is the edge (p=0.007 pooled)
Within full convergence (Regime 3/4 + premium ≤28, entry_quoteable, SML-era), SML side vs the nearest-25 body:

| SML side | n | win% (+50% target by 15:55) |
|---|---|---|
| **ABOVE body** | 178 | **59.0%** |
| none (no SML that day) | 53 | 52.8% |
| **BELOW body** | 107 | **42.1%** |

- Clean **ordinal** tilt: above > none > below. **ABOVE vs BELOW = +16.9pp, p=0.007, OR≈1.8.** Consistent across all
  3 checkpoints (11:30, 12:30 20W, 12:30 15W) — each single-checkpoint p≈0.2-0.3, pooled p=0.007.
- **Proximity to body is NULL/NEGATIVE** (wrong shape): tightening ≤10→≤5 is *monotonic worse*. Distance is not the signal; side is.
- 11:30 only: above 66.7%(n60) vs below 48.4%(n31), +18.3pp (p=0.115, small-n).

## Mechanism — the line is a CEILING (p=0.007), not just a marker
On SML-above convergence trades, tracking the SPX path (spx_1min) entry→15:55:
- **CLOSED BELOW the line (ceiling held): 66.7%** (n114) vs **CLOSED ABOVE (broke): 45.3%** (n64), **Fisher p=0.007.**
- Gradient by (close_1555 − line): 10-25 below 100%(n25) · 0-10 above 78.6%(n28) · 0-10 below 67.6%(n37) ·
  >25 below 50%(n52) · 10-25 above 41.2%(n17) · **>25 above 0.0%(n19).**
- So the entry tilt is **mechanistic**: the line above caps the upside, keeps SPX off the short body.
  **Gives a tradable EXIT signal: SPX sustaining above the line = edge broken (45%→0% if >25 above).**

## "What is the line?" — source is unverifiable by design; behavior is real
- Author's claim: a **standing dark-pool spot order "from swaps,"** size, unfilled until price comes to it.
  **No terminal shows a standing dark order; swaps flow is private dealer data; DTCC is EOD.** So the origin is
  the author's narrative and **cannot be corroborated** — expected, not evidence against. (PM's own read: "if it
  were me I wouldn't broadcast what it is — likely a subscription story, but that doesn't mean it's not real.")
- **Roundness test:** line within 0.25 of a multiple of 5 = **16.4%** (random null ~10%); of 10 = 7.4% (null 5%);
  of 25 = 3.0% (null 2%). Only ~1.5× random → **a specific/arbitrary tick, NOT a generic round number.** Against
  the "it's just a round number" debunk.
- **Net: the origin is a story we stop chasing; the tradable fact (repeatable specific level + ceiling + entry
  tilt + line-break exit) is real and independent of the narrative.**
- **Open (optional): exhaustion test** — does the ceiling *deplete* after repeated touches (finite order) or hold
  every time (structural level)? That's the failure-mode discriminator, not the edge confirmation.

## Convergence legs — premium leg is the strong one; regime 3/4 leg is WEAK this era
| Regime | Prem | n | win% |
|---|---|---|---|
| 3/4 | ≤28 (above/below/none pooled) | 338 | ~52.7% |
| other | ≤28 | 177 | 54.8% |
| 3/4 | >28 | 383 | 38.9% |
| other | >28 | 207 | 43.0% |
- **Premium leg (≤28 vs >28) = +13pp — strong, real.** **Regime 3/4 leg shows NO clear lift (3/4 ≈ other, within
  noise) in the SML-era sample** — opposite of the desk prior that R3/4 is best. **FLAG: possible post-2025-02
  regime shift OR SML-side interaction (3/4 is where above/below diverge most). Not yet broken down by
  regime × SML-side × year.**

## Gold cell (peel/runner) re-derivation — corrected the spec
- Source: `verifications/artifacts/2026-08-14_fly_hold_cut_surface_v1/`. 4 conditions: premium_at_touch≤26.5%,
  checkpoint∈{1130,1230}, regime=3, first_touch<14:30, threshold=1.50×.
- **n=52, 39 days, 2022-03→2026-08 (~12/yr)** — the spec's "40-70/yr" was wrong; "violence" is a calm-median /
  fat-tail profile (p25 −62.7%, min −126.7%; 55.8% reach 2× debit, 15.4% double-touch).
- **Mid marking: mean continuation +6.9% (CI [−14.1%, +27.9%])** → hold-all is the mean-EV corner at mid.
  **Worst-fill: mean −12.9%** (flips EV sign) → peel-all corner. ~20pp mid/worst-fill gap = execution edge.
- **Peel EV is linear in f; peeling 75% costs only 5.2% of touch in EV.** Defensible: **peel 60-75% at +50%,
  keep 25-40% runner sized as money you can lose entirely. Peel fraction is a PM DECISION (live position), not a
  study output.**

## Files / substrate
- `/data/agentic_trading/data/discord/strongest_lines.parquet` (the SML/SAL table).
- `/data/agentic_trading/outputs/fly_trades_nearest25.parquet` (8488 rows, 80 cols, 2021-05→2026-08; key cols
  `tradeDate, checkpoint_label, body_strike, entry_stock_price, entry_debit, wing_width, regime_id,
  target_hit_by_1555, entry_quoteable`).
- `spx_1min` in `research.duckdb` (SPX index 1-min, 11:00-16:00 ET). Body = `FLOOR((stockPrice+12.5)/25)*25`.
  Premium% = `entry_debit/wing_width*100`.
- Python venv: `/data/agentic_trading/.venv/bin/python` (pandas 2.3.3, pyarrow 25.0.1, duckdb 1.5.5, scipy).

## Open / next
1. **PM: decide gold-cell peel fraction** (60-75% peel / 25-40% runner defensible) — applies to a live position.
2. **Exhaustion test** (optional, failure mode): does the SML ceiling deplete after repeated touches?
3. **Regime 3/4 leg flag:** break down regime × SML-side × year — is R3/4 still doing work or a regime shift?
4. **Exit / hold-loser side (b):** on underwater convergence trades, does SML near/on the recovery side of body
   predict recovery-to-line (hang on) vs continuation to 2×?
5. **Hygiene:** change Discord password (invalidate token) → delete `~/discord-export/token`; add `data/discord/`
   to `.gitignore`.

## NOTES
- DuckDB reserved words on this box: `first`, `last`, `days` — must alias.
- Pandas precedence trap hit: `f.a==x & f.b==y` parses wrong — parenthesize each comparison.
- SML join: SML side table needs `pd.to_datetime(...).dt.date` to match; the spx_1min path join needs the
  `strftime('%Y-%m-%d')` string. Mismatch = silent n=0.
