# 100W iron fly L0.6 — upside-vs-giveback first-passage race (FROZEN exit geometry) (2026-08-26)

**Date:** 2026-08-26 · **Seat:** oc-ask · **Topic:** final unconditional path study — race outcomes, frozen exit geometry

Companion to `2026-08-26_iron_fly_100w_pm_ruling_conditional_entry.md` and `2026-08-25_iron_fly_100w_path_study.md`.

## What was built (L0.6, FROZEN)
After first touching level A (35/40/45/50% of credit), which resolves FIRST on the remaining
path: upside target B or giveback barrier D? With resolution times measured from the touch.
- Script: `scripts/iron_fly_race_100w.py` (read-only, deterministic, exit 0 on PASS)
- Commit: `66cd81c8` (script + race_matrix.csv + golden_path.json + self_check.json + 2 verify deposits; parquet excluded)
- Verify deposits: `verify/ironfly-100w-race-selfcheck.*`, `verify/ironfly-100w-race-independent-diff.*`
- Verification: all 5 self-checks PASS (V1 population 173/179/352, V2 partition, V3 monotone-in-D,
  V4 anchor hand recompute, V5 combined additivity) + MY independent raw-row recompute: 30/30 core
  rows and the full 91-row combined matrix EXACT match (deposited).

## Method pins (load-bearing)
- Race start = first index with pnl ≥ A·credit. From there: UPSIDE at first mark ≥ B·credit;
  GIVEBACK at first mark ≤ D·credit. B > D so no mark is both. Neither firing by Friday close
  = UNRESOLVED (own bucket; Friday 15:59 mark is NOT settlement).
- P(upside first) / P(giveback first) are **conditional on resolved** races; P(unresolved) separate.
- Time in hours from the touch. Path is hourly.
- Sign convention: pnl = fly_value_mid − entry_debit_mid; credit = −entry_debit_mid.

## The frozen numbers (combined 352; core rows)
| A | B before D | P(ups|res) | P(giv|res) | P(unres) | med hrs (all) | med hrs (up, if later than t0) |
|---|---|---|---|---|---|---|
| 35 | 45 before 25 | 0.714 | 0.286 | 0.000 | 0.10 | 1.79 |
| 35 | 50 before 25 | 0.641 | 0.359 | 0.000 | 0.27 | 2.31 |
| 35 | 50 before 15 | 0.725 | 0.275 | 0.004 | 0.47 | 4.08 |
| 35 | 50 before 0  | 0.785 | 0.215 | 0.033 | 0.75 | 17.92 |
| 35 | 60 before 25 | 0.506 | 0.494 | 0.000 | 0.45 | 3.29 |
| 40 | 50 before 30 | 0.696 | 0.304 | 0.017 | 0.03 | 0.75 |
| 40 | 55 before 25 | 0.674 | 0.326 | 0.017 | 0.22 | 1.40 |
| 45 | 50 before 35 | 0.810 | 0.190 | 0.009 | 0.01 | 0.40 |
| 45 | 60 before 35 | 0.634 | 0.366 | 0.009 | 0.20 | 1.68 |
| 50 | 60 before 40 | 0.731 | 0.269 | 0.010 | 0.07 | 0.84 |

(g5/g25 per-pool tables in `outputs/iron_fly_race_100w/race_matrix.csv` + `golden_path.json`;
g5 vs g25 differ by <~4pts — second-order, as in L0/L0.5.)

## The time-0 phenomenon (verified real, 53–58%)
For every core row, **~53–58% of upside resolutions occur at time 0** — the same hourly mark that
first touches A already sits ≥ B (a sharp intramark/intermark move clears several levels at once).
That is why raw median time-to-resolve looks tiny (0.01–0.27 h). The decision-relevant median is
the one CONDITIONAL on resolving later than the touch (last column: 0.4–4.1 h for the core band,
spiking to ~18 h for "50 before 0" because surviving without ever returning to zero until +15pts
means waiting out long decays).

## The empirical transition (PM-corrected, 2026-08-26)
The geometry is STATE-DEPENDENT: continuation probability is a function of (state, goal, barrier),
not a single universal boundary.
- **35 → 45 before 25: 71.4% hold** (fast: med 1.8 h if later)
- **35 → 50 before 25: 64.1% hold**; vs the 0-barrier it's 78.5% (17.9 h) — a much longer, stickier win
- **35 → 60 before 25: 50.6% — the first place continuation approaches indifference**
- **40 → 50 before 30: 69.6% hold**; 40 → 55 before 25: 67.4%
- **45 → 50 before 35: 81.0% hold** (best row in the band); 45 → 60 before 35: 63.4%
- **50 → 60 before 40: 73.1% hold**

**PM conclusion (frozen interpretation):**
1. Once the trade reaches the 35–50% profit zone, exiting merely because "the winner might
   disappear" is NOT supported by the unconditional path data: in most economically relevant
   10-point races, additional upside arrives before a comparable give-back ~64–81% of the time.
2. **60% is the FIRST MEANINGFUL CONTINUATION FRONTIER, not the natural exit boundary.** 45→60
   (63.4%) and 50→60 (73.1%) remain strongly favored. The first point where continuation loses its
   strong advantage is the +15-point extension asked of an EARLY 35% winner (35→60 = 50.6%).
3. The conditional study is re-scoped accordingly: not only "conditionals that make 35–45% occur
   more frequently" but "entry-state variables that improve BOTH acquisition AND continuation."
Unresolved rates are ≤3.3% (only for the deep 0-barrier rows), so the conditional-on-resolved
probabilities are close to unconditional.

## Next (PM sequence step 4, NOT started)
Split these race probabilities by Monday-11:30 entry-time conditionals. The frozen unconditional
geometry above is the baseline every subgroup must beat. Do NOT move to conditionals until PM says.

## Artifacts
- `scripts/iron_fly_race_100w.py` (committed `66cd81c8`)
- `outputs/iron_fly_race_100w/`: race_matrix.csv (91 pairs × 3 pools), golden_path.json (10 core rows × 3 pools), self_check.json, + .parquet (untracked)
- verify deposits as listed above
