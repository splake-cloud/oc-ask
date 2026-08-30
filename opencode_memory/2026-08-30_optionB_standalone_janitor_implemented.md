# 2026-08-30 — Option B standalone SQLMesh janitor: implemented + verified (patch for PM review)

## What was built/decided
Resumed a **dead** thread (prior agent hit `ContextOverflowError` right after inspecting the test harness, before dispatching the edit). The janitor work is a continuation of session `ses_fb1efa917ffeSS6g82KUZw5POe` (ran in `ses_faf61b019ffehSH6KMG2Rjdlew`). PM had already approved **Option B + 7 amendments**; the one-shot janitor had run clean (`verify/janitor_20260830T150018Z/`, dropped exactly the 2 authorized tables). Nothing had been applied — `daily_eod_build.py` was clean at baseline.

**Delivered (Option B, amended):** a temporary, gated, non-blocking standalone janitor step in `scripts/daily_eod_build.py` (+105 lines, 0 deletions) and `tests/test_daily_eod_janitor.py` (new, 314 lines, 22 mocked tests). **Nothing executed live; systemd unit UNTOUCHED.**

## Key facts settled (with paths)
- **Why the janitor never ran:** `Context.run()` calls `_run_janitor()` for prod by default (`sqlmesh/core/context.py:806-807`); the warehouse advance is `warehouse/shadow_run.py:146 ctx.run()`. The EOD unit runs `--skip-shadow` (PM hardening after the 2026-08-27 mystery write), which gates the only advance step → janitor + advance both skip. Warehouse is stale (pool `atm_iv_daily`=2026-08-28; warehouse=2026-08-25; M1/M2=2026-08-27).
- **The gate (Amendments 1+2):** `eligible = _shadow_skipped(steps) and _blocking_steps_ok(steps)` at `daily_eod_build.py:618`. `_shadow_skipped` (`:236`) True only when `warehouse_shadow.status=="skipped"` (i.e. `--skip-shadow` set → today's prod path). `_blocking_steps_ok` (`:242`) True only when all 8 of `BLOCKING_STEP_NAMES` are present AND `"ok"` → any build failure/interruption gates the janitor OFF. If the advance is later re-enabled (shadow `ok`/`shadow_alert`), the standalone janitor is skipped → `Context.run()` owns it → **no double execution**.
- **Non-blocking (Amendment 3) is structural:** `step_warehouse_janitor` (`:249`) returns only `ok`/`janitor_alert` (never `failed`); catches `TimeoutExpired` + generic `Exception`; the diag write is itself try/except'd. `all_ok` (`:637-639`) = `not (has_failure or shadow_failed)` keys only on `failed`/`shadow_alert` → a `janitor_alert` **cannot** fail the build.
- **Diagnostics (Amendment 4):** full stdout+stderr (untruncated) + command/exit_code/duration/timed_out/exception → `LOG_DIR/janitor_diag_<UTC ts>.json`; `StepResult.detail` = last line + `diag=` path.
- **Narrow (Amendment 6):** command is exactly `[VENV_SQLMESH, "-p", WAREHOUSE_DIR, "janitor"]` (`:254`), no flags; `VENV_SQLMESH = /data/agentic_trading/.venv/bin/sqlmesh`; no new CLI flag (deliberate deviation from draft §2's `--skip-janitor`); no log renumber (logs `[janitor]`, not `[12/12]`).
- **Unit runs** `.venv/bin/python .../daily_eod_build.py --skip-shadow` → the step becomes eligible on the next nightly fire with **no unit change**.

## Verification (all via `verify-run`)
- `verify/janitor_compile_ctlflow_20260830.*.txt` — `py_compile` exit 0.
- `verify/janitor_tests_20260830.*.txt` — `pytest tests/test_daily_eod_janitor.py -q` → **22 passed in 0.04s**, exit 0. Tests monkeypatch `eod.subprocess` + `eod.LOG_DIR` (tmp_path); no `import sqlmesh`; no real-dir write.
- Control-flow inspection → `studies/iv_weekly_substrate/receipts/2026-08-30_optionB_janitor_control_flow_proof.md` (amendment-by-amendment proof + execution plan).

## Open / next
1. **PM review** of the control-flow-proof doc (decisions: approve inert patch; authorize 5a preflight + one observed nightly run; confirm incident handoff).
2. **Stale warehouse = separate priority incident for the SQLMesh agent (NOT this seat)** — (a) why the 00:20:50 mystery write happened, (b) is the advance path safe to re-enable (Option A vs B), (c) how to recover the missing 2026-08-28+ frontier days. Option B does NOT fix staleness by design.
3. **Reassess removal** of the standalone step as redundant once the shadow path is cleared/restored.
4. Draft spec `2026-08-30_standing_janitor_draft.md` now superseded by the control-flow proof for Option B.

## Traps
- Session ID given by PM was the IV-backfill thread; the janitor decision lived in its continuation `ses_faf61b019ffehSH6KMG2Rjdlew` (title had gone stale to "IV substrate backfill M2 version discrepancy").
- `verify-run <label> <command...>` takes program + args as **separate** argv, not one quoted string (first attempt exit 127).
- `scripts/` is a namespace package (no `__init__.py`); import via `sys.path.insert(0, repo_root)` then `from scripts import daily_eod_build`. `.venv` (not `.venv-sqlmesh`, whose python is permission-denied) has market_research+orjson+sqlmesh 0.236.1+pytest 9.0.3.
- The console "Deleted object" lines are NOT the authoritative drop set (one-shot trap) — the physical-table diff vs `02_baseline_state.json` is.
