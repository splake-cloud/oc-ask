# Iron-fly mark-quality & economic valuation convention (2026-08-26)

**Date:** 2026-08-26 · **Seat:** oc-ask · **Topic:** how to value an iron-fly mark when a wing is
unmarketed or carries a nonsensical provider quote; PM-confirmed wings-only transform.

Companion to `2026-08-26_iron_fly_100w_race_frozen_geometry.md` (the frozen studies this overlays)
and the diagnostic `scripts/iron_fly_mark_diagnostic_100w.py`.

## MARK-QUALITY / ECONOMIC VALUATION NOTE (PM-confirmed)

The iron-fly substrate is valued from its four component options:
  + long put wing   - short put body   - short call body   + long call wing
Each leg is marked independently from the provider's observed / model-derived market.

The synthetic package mark is a **component valuation, NOT an arbitrage-free package quote.**
In deep-ITM / wide-spread conditions the (short) body leg midpoint may sit beyond the theoretical
100-point vertical cap while the opposite (long) OTM wing is correctly marked near zero; the
resulting four-leg synthetic mark can therefore fall slightly outside the fly's terminal payoff
bounds **without** indicating bad construction or corrupted source data.

### Per-leg marking convention
- **usable market** (bid>0, ask>0, bid≤ask, mid economically sane) → use the provider mark, kept
  even if a wide mid pushes the vertical past the 100-point cap.
- **owned (long) wing with no usable market / nonsensical mid** →
  `fallback_owned_wing_value = max(intrinsic, 0)`
  - OTM wing: intrinsic = 0  → value 0
  - ITM wing: intrinsic > 0  → value intrinsic (its economically defensible floor; zero would understate)

### Nonsensical-mark trigger (diagnostic / admissibility heuristic — NOT a no-arb theorem)
A provider midpoint is treated as a nonsensical feed mark (→ fall back to the leg's intrinsic) iff:
    provider_mid > intrinsic + 50  AND  provider_mid > 50
Purpose: catch empty/absurd quotes (e.g. 0/6909.9 → mid 3454.95 vs intrinsic 82.75) while leaving
normal-but-wide, economically plausible markets untouched. Scope: **wings only** (PM-confirmed).
The body legs are NOT transformed in this convention.

### Explicitly NOT done
- Do NOT clamp the package to [−100, 0] (would manufacture an unobserved price and suppress real
  information about how ugly component markets get).
- Do NOT zero a wing merely because its market is wide.
- Do NOT drop the fly / the timestamp / label the date or source corrupt.
- Do NOT modify the canonical substrate or the raw provider observations.

## The confirmed transform (implemented as an analysis/diagnostic overlay)

`scripts/iron_fly_wing_mark_overlay_100w.py` (read-only; substrate + frozen studies UNCHANGED):
  intrinsic(call wing) = max(spot − upper_wing_strike, 0);  intrinsic(put wing) = max(lower_wing_strike − spot, 0)
  IF provider_mid > intrinsic+50 AND provider_mid > 50:  transformed_wing_mid = intrinsic
  ELSE:  transformed_wing_mid = provider_mid
  fly_value_mid_adjusted = transformed_put_wing_mid + transformed_call_wing_mid − put_body_mid − call_body_mid
  (body legs = unchanged provider mids)

### Measured scope (100W, 352 eligible trades, 633,725 marks)
- **7,102 wing transforms** (put_wing 3,511 + call_wing 3,591).
- **5,789 marks / 34 trades** revalued (>0.01). Delta stats: mean −93.1, median −58.5, p05 −225.8,
  min −4,852.0, max −50.01.
- **627,936** untransformed marks unchanged (self-check S3, 0 failures).
- Bodies provably untouched (S4): fly_adj − fly_orig == Δput_wing + Δcall_wing for every mark.
- **Residual (out of wings-only scope):** 1,843 transformed marks still have |fly_adj|>150;
  1,540 of those carry a **body-leg** mid that would also trip the same test (e.g. 2024-04-26
  put_body mid 4952, intrinsic 0) — documented, NOT transformed, per the wings-only scope.

### PM-example verification (CORRECTED)
The PM's worked example used `upper_wing_strike ≈ 6060` (→ OTM, intrinsic 0). The actual mark
(body_grid=5, expiry 2025-04-11, valuation_ts 2025-04-09 13:23) has **upper_wing_strike = 5060**,
spot 5142.75 → the call wing is **ITM by 82.75**. So the correct transform is
`transformed_call_wing_mid = 82.75` (intrinsic), **not 0** — the ITM branch of the convention.
Independently recomputed: `fly_adj = 11.05 (put_wing, untransformed) + 82.75 (call_wing) − 25.0
(put_body) − 293.4 (call_body) = −224.60`, matching the overlay exactly. Self-check S2 PASS.

## Diagnostic result (construction root-cause, prior card `iron_fly_mark_diagnostic_100w`)
- Strike alignment + four-leg algebra verified correct (strike_rel_error=0; fly = −close_cost to 7e-13).
- **No construction bug → no model rebuild / no SQLMesh restatement required.**
- 3,102 economically admissible wide-spread/deep-ITM marks + 2 de-minimis boundary wobbles: KEPT.
- 8 genuine upstream wild ticks (concentrated 2025-04-07/09) → neutralized by the wing transform.

## Frozen studies & impact
L0 / L0.5 / L0.6 (path, continuation, race) remain frozen on the CANONICAL (untransformed)
substrate. The wing transform is an overlay, not a re-freeze. Even excluding the transformed marks
entirely moves the frozen geometry by <0.008 on core race probabilities and ≤4 trades on
enrollment — so the 64–81% / 60%-frontier conclusions are robust to this convention.

## Status
- Transform CONFIRMED by PM (wings-only; OTM→0, ITM→intrinsic; trigger mid>I+50 AND mid>50).
- Implemented + independently verified as an analysis overlay. Canonical substrate untouched.
- Artifacts: `scripts/iron_fly_wing_mark_overlay_100w.py`,
  `outputs/iron_fly_wing_mark_overlay_100w/{wing_mark_overlay.csv, wing_mark_overlay_summary.json, self_check.json}`,
  verify deposit `verify/ironfly-100w-wing-mark-overlay-selfcheck.*`.
- Committed: diagnostic `ff7640b2`, transform overlay `b5006972` (script + CSV/JSON + verify deposits each; no parquet).
