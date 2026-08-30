# 2026-08-29 — Iron Fly L2-B freeze + L2-C management-policy study

Session: `ses_fb620e9cbffeOUlOUGmzuLhAJb` (Iron Fly substrate refactor / L2-B recovery → L2-C)

## What was done

### 1. L2-B frozen (Option B banked conclusion)
- `studies/iron_fly_weekly/receipts/l2b_freeze.md` — authoritative freeze receipt with the
  PM's verbatim banked conclusion.
- **Key correction surfaced:** the frozen `friday_pnl` (and L2-B's `mean_Friday_PnL` /
  `Friday_win_rate`) is the **entry-day Monday 15:59 mark**, NOT the final Friday 15:59 mark.
  Verified 44/44 sample trades: last path row is always 15:59 on `entry_date+4` (Friday);
  frozen `friday_pnl` == first 15:59 close. `corr(Mon1559, Fri) = 0.086`,
  `mean|Fri−Mon| = 30.38` (nearly independent).
- True Friday hold P&L is **negative** for the primary populations:
  R>=0.70 → **-0.52**, R>=0.80 → **-0.77**, R>=0.90 → +1.40 (n=76, descriptive).
- **Field provenance rename** (provenance-only, CSV values/names NOT touched to keep hashes):
  `mean_Friday_PnL` → legacy/misnamed field representing Monday 15:59 P&L. Recorded in
  `receipts/l2b_freeze.md`, `verify/l2b_threshold_stability/friday_mark_drift.md`,
  and `verify/l2b_threshold_stability/v_proofs.json` (`field_provenance_rename` key).
- Banked conclusion (Option B): R is a **continuation-quality selector**, not acquisition.
  Gate R>=0.70 (n=290, ~82%), robustness R>=0.80 (n=184), descriptive R>=0.90 (n=76).
  **No claim of positive Friday hold P&L.**

### 2. L2-C built + verified (exit/management policy study)
- Spec: `studies/iron_fly_weekly/specs/iron_fly_L2-C_build_spec.md` (my design, not delegated).
- Script: `studies/iron_fly_weekly/scripts/iron_fly_l2c_management_policy.py`
  (qwen-coder build, dispatch `ses_fb1da0f59ffenqIEkQLffGtmth`).
- **16 prespecified policies:** HOLD (true-Friday last-row baseline), TP_35/45/50/60,
  GB(A,X) A∈{35,45,50}×X∈{10,20}, TRAIL_X X∈{10,20,30}, TIME_W (Wed 14:00), TIME_T (Thu 14:00).
- **V1–V11 ALL PASS.** verify-run transcript: `verify/l2c-build-full.20260829T153552Z.txt`.
- Outputs: `outputs/l2c_management_policy/` — `l2c_policy_eval.csv` (32 rows),
  `l2c_trade_detail.csv` (7584), `l2c_baseline.csv` (290).

### 3. Independent cross-checks (mine, not the delegate's report)
- TP exit_rate == frozen L2-B touch rates EXACTLY (R>=0.70):
  TP_35 0.710345, TP_45 0.631034, TP_50 0.589655 — same first-passage event.
- HOLD mean == my independent probe: primary -0.522672, robustness -0.772690.

## L2-C headline result (primary R>=0.70, HOLD baseline -0.52)
- **TP_50 dominates:** mean_exit_pnl +13.999 (Δ +14.52), capture 0.408, win 66.9%, exit 59.0%.
- TP_45 +13.551, TP_35 +13.515, TP_60 +12.437 (TP_60 falls off — fewer hits).
- GB (giveback-stop) policies: only +0.5 to +1.1 — they exit on the retrace, far below peak.
- TRAIL_X: ≈ HOLD (trailing stop triggers too early on noisy paths; TRAIL_10 even -0.48).
- TIME_T/W: +1.6 to +2.4 (checkpoint hold, modest).
- Robustness R>=0.80: same ordering, TP_50 +15.417 (Δ +16.19).

**Interpretation:** the favorable path (P35~70%, MFE~34) is fully given back by Friday under
HOLD (-0.52). A simple take-profit at 35–50% of entry credit converts it to +13 to +14 mean
P&L. Take-profit is the robust answer; giveback-stop / trailing / time-exit do not compete.
This is a prespecified-grid report, NOT an optimization — no threshold was tuned.

## Key facts / paths
- Canonical substrate: `warehouse.warehouse.iron_fly_weekly_substrate_v2` (v1103730983), read-only.
- Path span: Mon 11:30 (entry) → Fri 15:59 (last row), ~1,800 rows/trade.
- Proven path query: logical-trade tuple `(entry_ts, body_grid, wing_width, body_strike)`
  + NULL filter (`fly_value_economic IS NOT NULL AND entry_debit_economic IS NOT NULL`).
  `entry_spread_key` must NOT be a path filter (encodes row snapshot time).
- PnL = `fly_value_economic − entry_debit_economic`; entry_credit = `−entry_debit_economic`.
- Baseline ID: `0ceca8b978b22631d0b55b7b873ad1c4d0a65809857c2dc486791ed88834c486`.
- L2-C script hash: `4a335fe827c4c90be52f7b366a4e03c891f93d58a8511987d7c982160d35c45b`.

## Committed (branch `iron-fly-economic-baseline`)
Two commits, deliberately decoupled (PM principle: research correctness first;
filesystem cleanup must never gate the study):
1. `53f76c76` **research: freeze iron fly L2-B and L2-C management baseline** —
   321 files, all `studies/iron_fly_weekly/**`, all create-mode, zero deletions.
2. `50e2565c` **repo: relocate iron fly study artifacts** — 205 old-root deletions
   (the move counterpart of the reorg into `studies/iron_fly_weekly/`). Verified
   1:1 before staging: 190 pure moves (byte-identical), 12 move+edit (path/
   baseline_id updates, no content loss), 3 superseded (`v0_results.csv`+
   `v0_summary.txt` → `audit/`; `local_baseline.csv` frozen numerators preserved in
   `race_core.csv`/`continuation_core.csv`/`l2b_freeze.md`). 27 infrastructure files
   (warehouse model, scripts, `.ai` packets, builds) left untouched at root.
   HEAD transiently carried duplicate study artifacts between the two commits —
   accepted as harmless.

## Open / next
- L2-C result is a verified prespecified-grid report. PM to decide whether to bank it and
  whether TP_50 (or a TP band) is promoted to a live management rule (separate gate).
  That decision defines the next study.
