# 2026-08-24 — SQLMesh agent runtime: deploy walkthrough + oc_server.sh exec-bit fix

## What was done
- Walked the PM through end-to-end deployment of the sqlmesh-agent runtime
  (Gate 0 spec intake → Gate 1 builder dispatch → Gate 2 certification →
  Gate 3 guarded materialization → post-write verify → ledger/catalog close-out).
  Full command sequence verified against live components before presenting.
- Fixed `chmod +x /data/agentic_trading/rig/oc_server.sh` — had lost its exec bit
  (`-rw-rw-r--`, same failure class as the 8/18 `stg_spx_options_daily.sh` loss
  that died cron 6× with "Permission denied"). After fix: `status` runs clean.

## Key facts settled (with paths)
- Canonical deploy flow: `scripts/spec_intake_check.py` (Gate 0) →
  `scripts/dispatch_sqlmesh_builder_gated.py --spec <spec> -- --agent sqlmesh-builder
  --directory /var/tmp/oc_sqlmesh_builder ...` (Gate 1) →
  `scripts/certification_gate.py <candidate.json>` (Gate 2, atomic candidate→certified
  rename) → `.guarded_runtime/sqlmesh_executor.py` (Gate 3) →
  `scripts/post_write_verify.py` (baseline before, verify after) →
  `scripts/update_data_ledger_catalog.py` + commit.
- Live builder workdir is `/var/tmp/oc_sqlmesh_builder` (UNDERSCORE). The SEALED
  RAG card `sqlmesh_reference_local_agent_activation` and `docs/ACTIVATE_SQLMESH_BUILDER.md`
  say `oc_sqlmesh-builder` (hyphen) — VERIFICATION_RECEIPT.md:38-46 recorded the
  mismatch on 8/22 and the card was never corrected. Use the underscore path.
- Last completed end-to-end run: `weekly_vix_study` (certified + promoted, 921 rows,
  `BUILD_STATUS.txt` in workdir, 2026-08-23).
- Most recent candidate `iron_fly_weekly_substrate` (8/24 15:33): route=blocked —
  missing base spec sections 1-9, unresolvable Cboe option-session calendar source,
  45-vs-46 column count unresolved. NOT deployable until PM re-dispatches.
- Executor gotchas (documented in `.opencode/agents/sqlmesh-builder.md` Gate 3 section):
  `--` separator between executor flags and sqlmesh argv is mandatory; prod needs
  one-shot PM token (consumed BEFORE execution, binds normalized argv hash);
  non-interactive apply needs BOTH `--auto-apply` and `--no-prompts`; timeout =
  exit 3, outcome unknown, token already consumed — no retry with same token.
- opencode server: managed by systemd --user `opencode-server` (active, pid was
  1767858 at session time), :4096, auth Basic user=opencode, password in
  `~/.config/opencode-server.env`. `rig/oc_server.sh` is the only sanctioned way
  to interact; never `opencode run`.

## Tooling built this session (verified, uncommitted)
- `scripts/oc_dispatch.py`: (1) `from pathlib import Path` added — missing import crashed every `_log_dispatch` path (NameError) — verified via verify-run deposits `oc_dispatch_pathlib_fix.*` / `oc_dispatch_pathlib_diff.*`; (2) `_last_status()` + descriptive poll prints: `messages=N (Xs) tool=bash running <cmd>` / `reasoning` / `text: ...`. Stall timer still resets only on message-count change (a long tool call can't disable the no-progress deadline). 6/6 gated-wrapper tests pass.
- `scripts/dispatch_sqlmesh_builder_gated.py`: `_stale_deposits()` preflight — before Gate 0, scans `--directory`/`--out-dir` for prior-run deposits (BUILDER_RECEIPT.candidate.json, BUILDER_RECEIPT.json, BUILD_STATUS.txt, dispatch_* captures), prints `[stale-deposit] <path> (mtime ...)` per hit to stderr, records in log key `stale_deposits`. Non-fatal. Delegate deviation (reviewed, accepted): test allowed-imports set gained `time` (stdlib) at tests/test_dispatch_sqlmesh_builder_gated.py:269.
- Exec-bit scan (delegate, read-only): no scheduled script currently missing +x; `launch_qwen35_397b_tri.sh` intentionally un-exec'd (unit invokes via /bin/bash); `backup_to_sandisk.sh` latent (chmod'd by install script).
- Iron_fly gate0 dispatch (session ses_fcb18a5b8ffeR4dlxirsJ4Nv0u, 17:52) COMPLETED: 20 messages, no stall. Full source resolution (RAG curl, venv pyarrow/pandas_mark scans, duckdb info_schema, ledger check) → re-emitted `route=blocked`, spec sha 511d2e3b3c2bf99b, validation.* all null. 3 fundamental blockers: (1) Cboe option-session + XNYS scheduled-close sources unresolvable (3 mandated columns: option_scheduled_close, spx_scheduled_close, exit_feasible); (2) NEW — `spx_5min` POOL_LEDGER status is `PROPOSED — PM classification pending`, not PM-RATIFIED → not admissible for a prod table; (3) session_id/entry_spread_key PK construction rule absent from spec (two conflicting prior-art formats documented). No model/test produced. PM actions required: register/rule-out calendars (or redefine exit_feasible), ratify spx_5min, ratify PK rule + 45-vs-46 column count.
- Other live sessions checked: ses_fcc180ad6ffeq0Z106JIQZZOOC "Iron Fly weekly substrate build spec" (114 msgs, last activity pre-17:52), ses_fcb0c1bd9ffebfhsS4nrbkGOcv (18:06, config ctx-262144 commit/push work — separate lane).

## Incident: uncommitted _log_dispatch silently discarded (8/24 ~17:5x)
- `oc_dispatch.py` HEAD has NO logging (grep _log_dispatch on HEAD blob = 0); a 30-line `_log_dispatch` existed only as uncommitted working-tree state. Delegate's pathlib patch materialized file from HEAD+1 line → block lost. My verify-runs were pinned to HEAD so both passed. `logs/oc_dispatch/` was never created, which is why the user's "stuck at message 12" run (process dead mid-flight, no builder session after 17:52) left zero trace.
- PROCESS FIX: envelope clause 1 now pins the PRE-PATCH WORKING-TREE sha256 (first verify = it must match before any edit).
- REPLACEMENT: `_finish()` in oc_dispatch.py routes all 7 exits (preflight_only/refused/usage/transport_session_create/harness_fault_stall/transport/done) → drops `logs/oc_dispatch/dispatch_<ts>_<rc>.json` + prints `[exit] rc=N status=... log=<path>`. Session-create POST now guarded (was raw traceback). Verified: compile, unit (real log files dropped), 6/6 tests. Verify deposits: `oc_dispatch_exitlog_{compile,unit,tests,exits}.20260824T1826*.txt`.

## Iron_fly re-dispatch after PM cleared the 3 blockers (19:35–20:57)
PM's fixes, all verified: (1) nyse_calendar.parquet (1151 rows, 7 cols) + warehouse/models/nyse_calendar.sql + POOL_LEDGER ROOT_SOURCE (commit f4e89d55); (2) spx_5min → ROOT_SOURCE in ledger; (3) PK rule in spec S4 (session_id = trade_date + zero-padded 5-min bar index; entry_spread_key = + $0.50-bucketed body strike, PM-ratified). Residual gap closed by PM commit 1222d448: `calendar_path` variable added to warehouse/sqlmesh.yml:28. Gate 0 then rejected the refreshed spec twice on S3 mutability enum (missing on spx_5min entry; `append_only` invalid on calendar entry) → fixed both to `immutable` (rationale text supports it); Gate 0 PASS, spec sha now **5c761762c0d4978e5d416240740a45172517db99f97c605354a5c7f3954e7cdf** (inbox+workdir synced).
- Dispatch 19:37 (session ses_fcab8a588ffeh2eUhOEm4jpkFj): full source resolution PASSED (first time), model written 20:04, then **OOM-kill #1 at 20:07:12** (systemd-oomd, host swap pressure 36G/39G, unit peak 267M vs 8G cap — caps NOT the trigger; ManagedOOMSwap=auto). Dispatcher logged rc=4 transport (first live proof of the new exit logging). Model survived (298 lines).
- Resume ~20:3x (POST directly to session — dispatcher can't resume; it always POSTs a new session): seat re-verified state, edited model 20:50 (299 lines, 9 CTEs, pool source now @VAR('spx_pool_glob',…) matching stg_spx_options pattern — DIVERGENCE from spec's bare @spx_pool_glob, must be recorded in receipt), started selfcheck → **OOM-kill #2 at 20:54:21**.
- **State handoff written: /var/tmp/oc_sqlmesh_builder/STATE_RECEIPT_iron_fly.md** — what exists (model COMPLETE 299 lines, verified), what's missing (KASA test, fresh candidate receipt bound to 5c761762, validator run), 3 resume options (A same-session-no-subagent, B fresh dispatch, C any coder executor-outside-oc).
- STALE artifacts in workdir: BUILDER_RECEIPT.candidate.json (18:07, blocked-run, old sha 511d2e3b) and BUILDER_RECEIPT.json (8/23 weekly_vix) — both flagged by the new [stale-deposit] preflight on re-dispatch.

## Open / next
- If the user's "completed build file" is iron_fly: PM must re-dispatch with base
  spec sections 1-9 and rule on the calendar source before any gate run.
- Consider correcting the SEALED activation card's workdir path (hyphen →
  underscore) or a note that both have existed — PM call, not mine to seal.
- Watch for further exec-bit losses on cron-invoked scripts (2nd occurrence now).
