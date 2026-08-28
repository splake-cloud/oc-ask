# L1-D: OPTION POSITIONING / GAMMA STRUCTURE AT MONDAY 11:30

**Status:** COMPLETE — 352 trades (173 g5, 179 g25), 10 dates excluded to match frozen baseline.

---

## Population

- Total: 352 trades (173 g5, 179 g25), 173 paired weeks
- 10 dates excluded: grid=5 (8 dates), grid=25 (2 dates: 2025-03-21, 2025-11-21)
- L1-D1: 352 trades with stg_spx_options 1130 snapshots
- L1-D2: 56 trades with gamma_research data (entry_date >= 2025-12-12)

## Frozen Baseline (from pre-computed files)

**Acquisition:** P35=68.8%, P45=61.3%, P50=56.1%
**Path Quality:** P35→45=82.6%, P35→50=77.3%, P45→50=94.1%, P50→60=86.8%

## Key Signals (|delta| > 3pp, L1-D1)

### Path-Quality Selectors (improve continuation once touched)

| Feature | Bin | P35 | Δ | P35→45 | Δ | P35→50 | Δ |
|---|---|---|---|---|---|---|---|
| oi_gamma_total | L (low gamma) | 61.5% | -7.2pp | 94.4% | +11.8pp | 88.9% | +11.6pp |
| put_call_gamma_ratio | H | 68.9% | +0.1pp | 91.5% | +8.8pp | 87.8% | +10.6pp |
| delta_oi_imbalance | L (negative) | 71.8% | +3.0pp | 89.3% | +6.7pp | 84.5% | +7.3pp |
| oi_pcr_1130 | M | 69.8% | +1.0pp | 93.8% | +11.2pp | 85.2% | +7.9pp |

### Acquisition Selectors (raise touch probability)

| Feature | Bin | P35 | Δ | P50 | Δ |
|---|---|---|---|---|---|
| gamma_location_imbalance | L (gamma below spot) | 77.6% | +8.8pp | 66.4% | +10.3pp |
| oi_gamma_total | M | 73.3% | +4.5pp | 57.8% | +1.7pp |

## Interpretation

1. **Low oi_gamma_total** = strongest path-quality signal. When total OI gamma is low, fewer trades touch 35% (-7.2pp) but those that do are much more likely to continue to 45%+ (+11.8pp) and 50% (+11.6pp). This is a **conditional path-quality selector**: accept lower acquisition for higher continuation.

2. **Gamma below spot** = acquisition signal. When gamma inventory is concentrated below the current spot, more trades touch 35% (+8.8pp) and 50% (+10.3pp). This reflects the structural tendency for spot to move toward the gamma concentration.

3. **put_call_gamma_ratio H** = path-quality signal. When put gamma dominates call gamma, continuation improves (+8.8pp to 45%, +10.6pp to 50%) with no acquisition penalty.

4. **delta_oi_imbalance L** = path-quality signal. Negative directional imbalance (more put OI-weighted delta) improves continuation (+6.7pp to 45%, +7.3pp to 50%).

5. **oi_pcr_1130 M** = path-quality signal. Moderate put/call OI ratio improves continuation (+11.2pp to 45%, +7.9pp to 50%) with no acquisition penalty.

## L1-D2 (signed gamma, 56 trades)

Signals based on very small samples (n=3 in H bin) — provisional. net_signed_gamma H: P35=100% but n=3. atm_gamma_fraction L: P50=33.3% but n=6. **Not reliable for decision-making.**

## Dual-Selector Cross-Check

The oi_gamma_total signal is partially confounded with the L1-A ratio (entry_credit / friday_straddle). Low oi_gamma_total coincides with high credit/straddle ratio (Q4), suggesting the gamma signal captures part of the same mechanism as the ratio.

## Comparison to L1-A

- **L1-A ratio Q4**: P35=100%, P35→45=93.2%, P35→50=89.8% — dual selector (acquisition + path quality)
- **oi_gamma_total L**: P35=61.5%, P35→45=94.4%, P35→50=88.9% — path-quality only (lower acquisition)
- **gamma_location_imbalance L**: P35=77.6%, P35→45=87.8%, P35→50=85.6% — acquisition + modest path quality

The L1-A ratio remains the strongest dual selector. The oi_gamma_total and put_call_gamma_ratio signals are complementary path-quality selectors that accept lower acquisition for higher continuation.

## Files

- `/data/agentic_trading/scripts/iron_fly_l1d_positioning_v3.py` — study script
- `/data/agentic_trading/outputs/iron_fly_l1d_positioning_v3/l1d_results.csv` — 105 rows (11 features × 3 bins × 7 metrics)
- `/data/agentic_trading/outputs/iron_fly_l1d_positioning_v3/l1d_verification.txt` — verification appendix
- `/data/agentic_trading/outputs/iron_fly_l1d_positioning_v3/l1d_audit_traces.csv` — 3 spot audits

## Vocabulary

- stg_spx_options features: "OI-weighted gamma", "OI-weighted directional imbalance" (NOT "dealer gamma")
- gamma_research features: "signed gamma" (already dealer-SIGNED UW exposure)
