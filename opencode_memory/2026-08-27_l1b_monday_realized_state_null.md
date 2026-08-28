# L1-B — Monday Realized State (Null Result)

**No independent Monday realized-state selector identified.**

---

## Finding

Overnight gap, pre-11:30 direction, absolute movement, and realized range do not materially
discriminate the trade at coarse (tercile) binning. All deltas within ±0.5pp.

**The apparent `range / friday_straddle` effect is denominator-driven** and belongs to the same
relative-premium state already identified by `entry_credit / friday_straddle`, rather than
constituting a distinct realized-movement signal.

Rather than claiming mathematically that Monday movement contains zero incremental information,
L1-B found **no evidence of economically material incremental information at the tested coarse
resolution.**

---

## What L1-A Actually Found

This sharpens what L1-A identified. The emerging feature isn't simply "high credit" or "small
straddle":

| Feature | Signal? |
|---|---|
| `entry_credit` alone | No |
| `friday_straddle` alone | No |
| Monday movement alone | No |
| Monday range alone | No |
| `entry_credit / friday_straddle` | **Strong dual selector** |

The signal is in the **relative premium structure** — the ratio of what you collect at entry
to the straddle value at expiry. This captures the joint state of premium level and
realized-movement potential in a single normalized metric.

---

## Test Matrix

| Variable | Valid | Range | Best delta | Verdict |
|---|---|---|---|---|
| overnight_gap | 352 | -6.2% to +8.0% | ±0.2pp | No signal |
| abs_overnight_gap | 352 | 0% to 8.0% | ±0.2pp | No signal |
| open_to_1130 | 352 | -7.2% to +5.6% | ±0.2pp | No signal |
| abs_open_to_1130 | 352 | 0% to 7.2% | ±0.2pp | No signal |
| range_pct | 352 | 1.0% to 11.5% | ±0.2pp | No signal |
| range / friday_straddle | 352 | 0.95 to 55.6 | +0.3pp | Denominator artifact |

All tercile bins, acquisition and path-quality deltas vs frozen baseline (P35=68.5%, P45=60.5%,
P50=56.0%, P35→45=80.9%, P35→50=74.7%, P45→50=90.1%, P50→60=80.2%).

---

## Spot Audit

`range / friday_straddle` H bin (n=119) verified independently: P35=100%, P45=95%, P50=88%.
Correlation with `friday_straddle` = -0.39. H bin straddle mean = 25.10 vs L bin = 151.25.
Confirms denominator-driven selection, not distinct movement signal.

---

## Source

Substrate: `warehouse.warehouse.iron_fly_weekly_substrate_v2`
Eligible: 352 trades, 2022-06→2026-08
Bin method: tercile (33/33/34 split)
Denominator: conditional on bin membership (not population)
Date: 2026-08-27
