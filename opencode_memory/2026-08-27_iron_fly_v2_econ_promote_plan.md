# Iron fly v2 economic substrate — normal `plan prod` promotion (pre-token verification)

> **⚠ SUPERSEDED (2026-08-30):** The "22:35 RESTATE was a no-op" conclusion in this card (section
> below, line 21) is **wrong**. The restate **did** rewrite the physical table `__1230283500`
> (a real `DELETE`+`INSERT`, verified in the run log). The "no-op" framing was correct only in
> the narrow sense that it re-ran the *pre-patch* definition and created no new version — but it
> **did** change the bytes, which is the row loss the incident tracked. See the forensic
> correction: `2026-08-30_stale_warehouse_incident_forensics_recovery.md` (this memory dir) and
> `studies/iv_weekly_substrate/receipts/2026-08-30_stale_warehouse_incident_forensics_and_recovery_plan.md`
> (D1). The original record below is preserved verbatim for provenance.

**Date:** 2026-08-27 · **Seat:** oc-ask · **Topic:** promote patched `iron_fly_weekly_substrate_v2` (economic leg marks + `entry_debit_economic`) via a **normal** `plan prod` (NOT restate), pre-token risk resolution + categorization de-risk.

Companion to `2026-08-25_iron_fly_substrate_v2_sixcell.md` (the v2 build + v1→v2 transition, done). This card is the **economic-patch re-promotion** on top of the live `__1230283500` table.

## The change (committed `c2da4c04` + `951a526c`)
Patched `warehouse/models/iron_fly_weekly_substrate_v2.sql` (15,542 → 19,190 bytes):
- `with_economic` CTE (lines 301–328): 4 intrinsics + 4 economic leg marks + `fly_value_economic`.
- `with_econ_entry` (lines 333–340): `entry_debit_economic` on **path basis** — at 11:30 anchor `pnl_economic = 0`, so `entry_debit_economic = fly_value_economic`.
- Monday path capped at 15:59 (else ≤15:59).
PM-locked: substrate carries raw/provider + 4 intrinsics + 4 economic leg marks; studies read banked fields only.

## PM-ratified sequence (replaces the retired restate path)
1. Canonical root `/data/agentic_trading/warehouse`.
2. Read-only `diff prod` must show **exactly** the intended v2 change (single model `warehouse.iron_fly_weekly_substrate_v2`; reasons = Monday ≤15:59 cap + economic intrinsic/leg/package fields + `entry_debit_economic`). Any other direct model change or env/requirements drift = **do NOT auto-apply**.
3. **Normal** `plan prod --auto-apply --no-prompts` (NO `--restate-model`) → changed model gets a NEW snapshot version → new physical hash backfilled → SQLMesh promotes the stable view.
4. Then run Gates 1–9 (`scripts/iron_fly_v2_econ_gates.py`).
Token argv hash: `bcbc7f0d354237f442805c0293fecab35f7753f55514e9868483263d46b9e04d`.

## Why the 22:35 RESTATE was a no-op (root cause)
`plan prod --restate-model ...` **re-backfills the model definition stored in STATE** (`_snapshots` row 576763739 → data_hash 741154747), NOT the working-tree file. So restate re-ran the **pre-patch 48-col** definition into `__1230283500` (grep `with_economic` = 0 in the run log), created no new version, did not promote the view. That is why PM switched to a **normal plan** (which reads the working tree). Log: `warehouse/logs/sqlmesh_2026_08_26_22_35_23.log`.

> **⚠ CORRECTION (2026-08-30):** "no-op" is wrong in the sense that matters. The run log shows a
> real `DELETE FROM ...__1230283500 WHERE trade_date BETWEEN '2022-06-01' AND '2026-08-24'` +
> matching `INSERT`, then `Promoting/Finalizing environment 'prod'`. The restate **did** rewrite
> the physical table (1,939,361 → 1,930,133 rows; 08-18..21 not re-derived). It was a no-op only
> re: *version* (no new snapshot, view not promoted) — not re: *bytes*. The byte change is the
> actual row loss. See the 2026-08-30 forensic correction (linked in the banner above).

## CATEGORIZATION DE-RISK (the key finding of this session — CORRECTS an earlier wrong assumption)
Earlier I assumed auto-categorization was OFF (no `plan:` section) → change would be UNKNOWN → `--no-prompts` would fail. **That was wrong.** Empirically verified in installed sqlmesh 0.236.1 (all read-only, no token):

- `PlanConfig.auto_categorize_changes` **defaults to `CategorizerConfig()` = `sql: FULL`** (`config/plan.py:27`, `config/categorizer.py:17`). No `plan:` section in `sqlmesh.yml` → **auto-categorization is ON (FULL) by default**, NOT off. Confirmed by loading the live config: `plan.auto_categorize_changes.sql = FULL`, `virtual_environment_mode = FULL`, `plan.no_prompts = True`.
- `is_breaking_change(old_model)` for our exact change returns **None** (verified by parsing old `14c7e148` vs new `c2da4c04` files with the project dialect+variables). With FULL mode, `categorize_change` maps `None → BREAKING` (conservative default, `snapshot/categorizer.py:43-46,65-66`).
- **Definitive read-only `plan_builder("prod").build()` against the real DB** (no writes, no apply):
  - `plan.uncategorized` = **0** → the `--no-prompts` `UncategorizedPlanError` (context.py:1834) **cannot trigger**.
  - substrate snapshot: old version `1230283500` → **new version `1103730983`**, `change_category = BREAKING`, `forward_only = False`.
  - Only ONE modified snapshot (the substrate); no added snapshots. So the backfill is scoped to the substrate only (no downstream sqlmesh model depends on it — confirmed by grep over `models/`+`audits/`).
- `categorize_as(BREAKING, forward_only=False)` + full virtual env → `version = fingerprint.to_version()` (`snapshot/definition.py:1149`) = a **NEW physical version**, exactly the PM-ratified "new version → backfill → view promotion" path. (NOT an in-place rebuild of `__1230283500`.)

**Bottom line:** the categorization risk is fully resolved. A normal `plan prod --auto-apply --no-prompts` will (a) not hang on a prompt, (b) not raise UncategorizedPlanError, (c) create new version `1103730983`, backfill it, and promote the stable view. The `diff` "(Unknown)" label I saw is the `ContextDiff`/fingerprint display label (`console.py:75 None:"Unknown"`), which is a **different** thing from the plan-time `categorize_change` that gates `--no-prompts` — a red herring, now cleared.

## Data anomaly still OPEN (writer unidentified)
Physical `__1230283500` dropped 1,939,361 → **1,930,133 rows** post-restate (trade_date 2026-08-18..21 gone; max date now 2026-08-17; 1,080 Monday after-close rows still present; no economic cols). Last DB write 00:20:50 UTC; only adjacent log `sqlmesh_2026_08_27_00_20_48.log` is a 2-sec connect-only run; no sqlmesh process running; backup cron 02:00 + `stg_spx_options_daily.sh` 06:30. `_intervals` (576763739) still claims coverage to 2026-08-26 = state/data inconsistent. **The new-version backfill is independent of this** (separate physical table `__1103730983`), so it does NOT block the promotion — but the old table is left state-inconsistent and the writer is unknown. As of 03:07 UTC: no writer process, no new writes since 00:20:50, 02:00 backup window already passed → environment quiet.

## Mirror-job governance (open)
Second project root `/data/warehouse/warehouse/` (marketdata-owned, same DB, own `models/`+`sqlmesh.yml`) received a mirror-sync of the patched model at 23:30:35 (byte-identical). Owner of the mirror job UNKNOWN. Both roots' `logs/` get identical sqlmesh logs; `/data/warehouse/warehouse/sqlmesh.yml` also touched 23:31.

## Harness (built + verified)
`scripts/iron_fly_v2_econ_gates.py` — Gates 1–9, flags `--db/--new-hash/--mode sample|full/--selftest`. Selftest ALL_PASS (`verify/ironfly-v2-econ-gates-selftest.20260827T011629Z.txt`); negative control vs `__1230283500` correctly FAILs G2/G3/G5–G9 (`verify/ironfly-v2-econ-gates-negative-control.20260827T011638Z.txt`). Mark rules transcribed from the installed model file, not memory.

## Recurring RW writer — DISABLED (2026-08-27)
**Writer identified:** `daily_eod_build.timer` → `daily_eod_build.service` → step 10 `warehouse_shadow` → `shadow_run.py daily --include-pool` → `ctx.run()` → RW write to `/data/warehouse/warehouse.duckdb`. Persistent=true, fires daily at 23:30 UTC (19:30 ET).
**Patch applied (PM):** `daily_eod_build.service` ExecStart changed to `…/daily_eod_build.py --skip-shadow`. `systemctl daemon-reload + restart timer` done. Live `ExecStart` confirmed: `argv[]` includes `--skip-shadow`. Steps 1–9 (parquet rebuilds) still run; step 10 (warehouse shadow/RW) is skipped. The `warehouse_shadow_cron.sh` interim wrapper is already dormant (removed from user crontab, last run 2026-08-16).
**00:20:50 mystery write:** unattributed (no journal entry, no cron, no systemd unit). EOD build finished at 23:32:28. Possible: DuckDB WAL checkpoint from EOD's `ctx.run()`, or one-off manual SSH intervention. **No longer a blocker** — the recurring RW writer is disabled, so the new-version backfill is isolated.

## Next steps (pending PM)
1. Mint + pre-validate token for `['sqlmesh','-p','/data/agentic_trading/warehouse','plan','prod','--auto-apply','--no-prompts']` (hash `bcbc7f0d…`).
2. Execute guarded plan (bash timeout ≥ ~40 min; backfill expected ~7–10 min). Confirm new version `1103730983` + promoted view in logs/state.
3. Run Gates 1–9 via verify-run (`--new-hash 1103730983 --mode sample`, then `--mode full` for Gate 6).
4. Phases 1–5: switch 8 consumer scripts to stable view + economic fields; stop+report after each.

## Key files
- `warehouse/models/iron_fly_weekly_substrate_v2.sql` (patched `c2da4c04`, 19,190 bytes) — rule source of truth.
- `scripts/iron_fly_v2_econ_gates.py` — Gates harness (verified).
- `warehouse/logs/sqlmesh_2026_08_26_22_35_23.log` — the no-op restate (pre-patch def).
- `/data/agentic_trading/.guarded_runtime/sqlmesh_executor.py` — argv build + `compute_normalized_hash` + token validation (consumed on exit 0 only, no internal timeout).
- `/data/warehouse/warehouse.duckdb` — 26.8 GB data+state, single writer, no `.wal`.
- 8 consumers (Phases 1–5): `iron_fly_{path,continuation,race,straddle_overlay,wing_mark_overlay,mark_diagnostic}_100w.py`, `iron_fly_v2_{raw_rederive,spot_check}.py`.
