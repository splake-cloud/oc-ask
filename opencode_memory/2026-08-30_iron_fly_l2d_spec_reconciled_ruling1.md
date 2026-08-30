# Iron Fly L2-D continuation markers — spec reconciled to build (PM ruling 1)

**Session:** `ses_fb038b696ffeLp0BsFkFcdc6n9` (resumed after ctx exceeded compactable limit)
**Date:** 2026-08-30
**PM ruling:** "1 and delegate to qwen-coder" — ruling 1 = in-conversation amendments are
operative; keep the build; correct the spec to match.

## What was decided / built

- **Ruling 1 executed.** The build `scripts/iron_fly_l2d_continuation_markers.py` is
  **untouched** (it already satisfies the amendments and passes V1–V11 11/11, exit 0).
- **Spec reconciled.** `specs/iron_fly_L2-D_build_spec.md` now matches the build on every
  load-bearing point. Only one line needed changing (see below); the rest was already correct.

## Key finding — the "conflicting v2" was already resolved on disk

The previous (compacted) session reported a **437-line "v2 spec"** whose 25-marker table
conflicted with the build on three load-bearing points (A/B/C) plus a stale k6=6 lookback.
**That file is no longer on disk.** The spec on disk is **457 lines** and its table (lines
220–246) header reads *"authoritative — matches the implemented, verified build."* All four
flagged conflicts were **already corrected** before this session resumed:

| # | Point | "v2" the prior session saw | Spec on disk now | Build (verified) | Match |
|---|-------|----------------------------|------------------|------------------|-------|
| A | Median direction | uniform `continue iff marker >= median` | per-marker HIGH/LOW/DESC (lines 193–198) | HIGH/LOW/DESC | ✓ |
| B | Approaches/rejections | 5pp band-runs | up/down-crossings of L (184–192) | up/down-crossings | ✓ |
| C | Marker set + natural rules | slope_k6_C, straddle_ratio, touch_dow>=3, hhmm>=1200 | build's 25 + before_noon/early_week/etc. | same | ✓ |
| — | Lookback | k6=6 (30 min, stale 5-min grain) | 30/60 snapshots (175, 212) | 30/60 | ✓ |

So the prior session's "which contract is operative?" question was moot — the operative
contract (amendments) was already the one on disk.

## Build's operative contract (extracted via qwen-coder EXPLORE, cross-checked)

- **25 markers** (order in `MARKER_NAMES`, lines 122–130): elapsed_hours, touch_isoweekday,
  touch_hhmm, slope_30/60, accel_30/60, rise_frac_30/60, path_std_30/60, prior_dd_depth,
  prior_dd_duration, n_approaches, n_rejections, spx_disp_entry, spx_disp_body,
  spot_in_wing_pos, spx_slope_30/60, straddle, straddle_vs_entry, put_body_iv, call_body_iv,
  body_iv_avg.
- **Median direction** (`MEDIAN_DIRECTION`, 146–165): HIGH = continue iff ≥ median
  (slope_30/60, accel_30/60, rise_frac_30/60); LOW = continue iff < median (prior_dd_depth,
  prior_dd_duration, n_approaches, n_rejections, spx_disp_body, put/call_body_iv,
  body_iv_avg); DESC = descriptive only, NOT a hybrid rule (11 markers). Hybrid uses 14
  (6 HIGH + 8 LOW).
- **14 natural rules** (`NATURAL_RULES`, 509–527, identical A/B): before_noon (hhmm<1200),
  early_week (dow≤3), slope_pos_30/60 (>0), accel_pos_30/60 (>0), net_rising_30/60 (≥0.5),
  prior_dd_present (<0), first_approach (==0), no_rejection (==0), inside_wings (|v|<1),
  straddle_expanded (>0), moving_toward_body.
- **Approaches/rejections** (432–440): `L=((A_pct−10)/100)·C` (25%·C for A, 35%·C for B);
  `n_approaches` = up-crossings `pnl[j−1]<L≤pnl[j]` for j∈[1,t); `n_rejections` = down-crossings
  `pnl[j−1]≥L>pnl[j]`. Rows strictly `< t`.
- **Lookback** `LOOKBACKS=[30,60]` (line 89). No k6.
- **SPX carry-back** `_spx_eff` (232–238): spx[t] else spx[t−1] else None; max 1 snapshot back,
  never forward. (EXPLORE report quoted `spx[t] is not not None` — a transcription slip; the
  actual line 234 is `spx[t] is not None`, correct. Independently read back.)
- **Giveback barrier** = touch level − 10pp (A: 35→25, B: 45→35); GB=0 sensitivity only.

## The one edit made (delegated to qwen-coder, verified by read-back)

Stale closing line 456 "Dispatch is held pending PM approval of the Marker Definition
Table (§5)" was false (table approved, build complete + V1–V11 passing). Replaced with:
> This blueprint is the complete semantic contract for the L2-D continuation-marker study.
> **The Marker Definition Table (§5) is approved (PM ruling 1, 2026-08-30): the
> in-conversation amendments are operative, and the table matches the implemented, verified
> build (`iron_fly_l2d_continuation_markers.py`, V1–V11 all PASS).** No implementation or
> production state has been altered by this revision.

Verified: `grep "Dispatch is held"` → no match; line 4 `Revision: v2 (… supersedes v1)`
untouched; file now 459 lines.

## Frozen facts (unchanged, re-confirmed)

- Populations 290 (primary R≥0.70) / 184 (robustness R≥0.80).
- Touch counts: STATE A 206/132, STATE B 183/120.
- Benchmarks: TP35 primary mean 13.515, TP50 primary mean 13.999.
- No source modified.

## Open / next

- Nothing blocked. The L2-D study is build-complete and spec-consistent. The next step is
  the actual **analysis/interpretation** of the marker-separation + hybrid-policy results
  (which continuation rule, if any, improves the TP35-vs-TP50 tradeoff) — that is the study's
  real answer and was NOT the subject of this reconciliation session.
- Prior session's open question (which contract is operative) is CLOSED: the amendments
  (ruling 1) are operative and the spec now says so explicitly.
