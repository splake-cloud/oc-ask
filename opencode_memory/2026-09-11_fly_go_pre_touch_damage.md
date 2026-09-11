# 2026-09-11 — SPX 0DTE put-fly: 11:30 GO trades, pre-touch damage + time to +50% touch

PM question (butterfly "fly" research, NOT iron fly): for 11:30 20W entries in the GO
range (premium ≤ 30% of wing) that reached the +50% touch, what is the normal
pre-touch damage and how long does the touch take? Winners only.

## Result (banked 2026-09-11)

Population: 470 trades, 2022-01-07 → 2026-08-20 (1130_20W, entry_quoteable,
`fly_entry_premium_pct` ≤ 30 — verified identical to debit/20wing×100).
Winners: 286 on **mid mark** (sealed runner-study convention, `fly_value_mid ≥ 1.50×debit`);
252 on **liquidation mark** (script2g `target_attained`, wings-at-bid/body-at-ask).
GO hit rate: 60.9% (mid) / 53.6% (liquidation).

**Time to +50% touch (from 11:30):**
- mid: mean 188 min, **median 196 min (~14:46)**, p25 153, p75 229 (~15:19), p90 251
- liquidation: mean 205 min, median 214.5 min
- only 39.5% touch by 14:30; 54% by 14:50. Rule of thumb: touch arrives ~14:45,
  plan 14:30–15:20, NOT before 14:30.

**Pre-touch damage (bars strictly before touch bar):**
- premin = min(fly value / debit): mid mean 0.51, **median 0.64** → median winner's
  mark fell to ~64% of debit (−36% of premium) pre-touch; mean damage −49.5%
  (63% of winners stay under −45%; 15/286 = 5% went to a NEGATIVE mark, tail to −6.9×)
- liquidation mark harsher: median premin 0.45 (−55%)
- price excursion: max SPX above body pre-touch = **median 20.6 pts** (a full wing-width),
  mean 24.4, p75 31.6, p90 47.1; vs entry spot median 17.1 pts
- 19/286 never went above the body; 81/286 went >30 pts through the upper wing

Robustness: by period C (≥2024, n=177) median 183 min / premin 0.67 (recent = faster,
less damage); A (n=63) 222 / 0.59. By regime R3/R4 (n=193) ≈ full population
(195 / 0.63) — sealed study's R3/R4 filter did not distort these stats.

## Method / sources

- Durable study artifact: `studies/0dte_fly/go_pre_touch_damage.md` (commit da458cd3).
- Paths rebuilt from 1-min `spx_options` in `/data/parquet/research_v2.duckdb`
  (same machinery as sealed `fly_hold_cut_surface_v1` at
  `verifications/artifacts/2026-08-14_fly_hold_cut_surface_v1/`, minus its regime filter).
- Cross-checks: liquidation touch times = script2g `first_hit_time_50` **252/252 exact**;
  mid touch times = sealed `touch_events_v1` **189/190** (1 miss 2026-07-23, 4 bars =
  post-seal quote re-harvest).
- Scratch: `/tmp/go_fly_pre_touch_analysis.py`, `/tmp/go_fly_winners.csv`, `/tmp/go_fly_all.csv`.

## Cautions

- Two mark conventions give two "winner" populations (286 vs 252) — not an error;
  mid = research/runner convention (sealed study's declared primary for path analysis),
  liquidation = executable. Don't mix.
- `min_return_pct_to_1555` in the script2g panel is WHOLE-DAY, not pre-touch — wrong
  column for this question.
- Negative premin values are real (net-short-delta structure beyond the wings), not
  data corruption, though missing-quote bars (bid=0) can exaggerate them.
- Sealed study `fly_hold_cut_surface_v1` is R3/R4-only; do not cite its numbers as the
  full GO population.
- Continues the 2026-09-04 fly loss-cut MAE card (`2026-09-04_fly_loss_cut_mae.md`).

## 2026-09-11 (cont.) — 11:30×12:30 body-match confluence + top-3 gamma node (banked, commit e59f8713)

Same thread, two more 11:30 GO entry-condition findings. Durable artifact:
`studies/0dte_fly/go_1230_confluence_and_gamma_node.md` + reproducible scripts
`studies/0dte_fly/scripts/verify_go_1230_confluence.py` and `verify_go_gamma_node.py`
(exit rule throughout: sell at 1.5× the 11:30 debit or the 15:55 mark).

**Finding 1 — body-match confluence.** The 11:30×12:30 body-match hit-rate uplift is
real on the FULL 20W population (match 58.6% vs no-match 47.4%; B0 +2.8% vs −19.1% per
$1) but it lives in the 11:30 fly already held — free by holding. A 12:30 add on a
match (paying +2.7% premium) is **EV-flat on the full population (+0.0%/$1)** and +EV
only on the GO/cheap slice (+5.2%/$1). This reconciles the sealed body-shift study
(12:30-fly's-own-target, full pop → "no EV edge") with the GO-subset sim (+EV): different
populations, both right in their slice. Do not pay the 12:30 premium to add on the full
pop; on the GO slice it's a small +EV.

**Finding 2 — top-3 gamma node near the body (era-split).** The node's sign FLIPS by feed
era. All-expiry era (≤2026-06-29): NEGATIVE (node3 −16.7%/$1, hit 44.8%). 0DTE era
(≥2026-06-30): POSITIVE (near3 +26.8%/$1, hit 78.6%). A pooled "node doesn't help" is an
era-mixing artifact (all-expiry dominates the sample). On the CURRENT 0DTE feed the node
helps. Key era off `trade_date_et`, never the `expiry` column. node3/near3 incidence is
~32–33%/49–50% in both eras (no incidence confound).

**Process note:** PM flagged both my earlier conclusions as suspect — (a) the 12:30
confluence result, (b) "the node doesn't help." Both were right to be suspect: the
confluence result is population-dependent and the node result was an era artifact. PM
directed: run the numbers, every claim carries PROOF, do not defer to prior research
(the body-shift study used a different target + population) or to priors. Re-ran both
cleanly, era/population-separated, with verbatim output.
