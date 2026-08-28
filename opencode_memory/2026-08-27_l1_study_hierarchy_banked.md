# L1 Study Hierarchy — Banked 2026-08-27

## Population Governance

- **Frozen baseline:** 352 trades (173 g5, 179 g25), 173 paired weeks, 2022-06→2026-08
- **Substrate drift:** substrate grew from 352 to 362 trades (10 new dates)
- **Remediation:** 10-date exclusion restores 352-trade population
- **Lesson:** study population is a governed artifact, NOT inferred from current substrate. Every subsequent script must explicitly state the population definition and exclusion list.

## Signal Hierarchy

### L1-A: `entry_credit / friday_straddle` — PRIMARY DUAL SELECTOR
- Q4: P35=100%, P35→45=93.2%, P35→50=89.8%, P45→50=95.5%
- Simultaneous acquisition lift (+38.7pp) and path-quality lift (+10.6pp)
- **Dominant signal**

### L1-D: OPTION POSITIONING / GAMMA STRUCTURE — COMPLEMENTARY

| Signal | Type | Key Delta | Interpretation |
|---|---|---|---|
| oi_gamma_total low | Path-quality | P35→45=+11.8pp | Worse acquisition (-7.2pp), better continuation |
| put_call_gamma_ratio high | Path-quality | P35→45=+8.8pp | No acquisition penalty, better continuation |
| gamma_location_imbalance low | Acquisition | P35=+8.8pp | More touches, modest path quality |

**Positioning is complementary to the premium-retention ratio, not a substitute.**

## Null Studies

- **L1-B:** Monday realized state — null (all ±0.5pp)
- **L1-C:** Volatility regime (IV, RV, term structure) — null (all ±0.1pp)

## Next: L1-E — Interaction / Incremental-Value Study

Test whether L1-D signals ADD incremental value beyond L1-A ratio, or are confounded.
