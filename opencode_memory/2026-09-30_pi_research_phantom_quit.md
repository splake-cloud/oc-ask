# 2026-09-30 — pi "force-killed when a run stops": pi-research phantom-quit watchdog, root-caused + fixed + committed

**Sessions:** research_agent pane (jett-8011, `spx_0050_gamma` %109) did the primary
investigation; the agentic_trading pi seat (jett-8011) ran the independent review + commit.

## What was decided / built

- **Root cause of the recurring "pi gets force-killed" deaths (NOT the ctx-400 wall from
  the morning, NOT OOM, NOT process_guard, NOT a node crash):** `@lincoln504/pi-research@1.7.1`
  treated `session_shutdown(reason='quit')` as "the process is exiting" and armed a
  **process-wide hard exit at +35 s** (`shutdownManager.forceExitAfter(35000)` →
  `process.exit`). But pi also delivers `quit` for **in-process child sessions**
  (pi-subagents) while the host keeps running — a subagent run ending ("when a run stops",
  the user's exact words) armed the kill in a live host. The SDK cleanup tasks' own
  per-task deadlines (core-services 15 s + scheduler ~12 s + ONNX embedder 12 s + 1 s)
  sum to more than the 35 s watchdog, and on this host teardown is always on the slow path
  (09-29: onnxruntime-node/Dawn native teardown broken on headless Intel/lavapipe — the
  WebGPU SIGSEGV card; cpu pin in `~/.pi/research/config.env`), so the watchdog fired
  every time.
- **Evidence (receipt `verify/apply-port-per-task-deadline.20260930T210458Z.txt` + live log):**
  `/tmp/pi-research.log` — pid 394029 (the pane's long-lived pi hosting the 13:11→19:43
  sessions) logged `[ShutdownManager] Forcing exit after 35000ms timeout` at 19:48:57.595;
  arm time 19:48:22.6 = mtime of `~/.pi/research/state/backups/research-state-…19-48-22-610Z.json`;
  subagent output file died mid-turn 19:48:54.68. 5+ such force-exits in 24 h
  (00:15, 00:38, 13:10, 15:43, 19:48, 20:24).
- **Fix (applied to live node_modules 20:53–20:55, then banked):** per-task deadlines in
  `utils/shutdown-manager.ts` (task abandoned at its deadline, process never exited) +
  `index.ts` no longer arms any process-wide force-exit on quit. **Running pi processes
  keep the old in-memory code until restarted** (4 user sessions: 651794 [12 d old],
  925306, 1082594, 1084631 — none restarted as of receipt).
- **apply-port.py rebuild (the durable restorer):** the working-tree (uncommitted) version
  of the day was found BROKEN — its embedded patch **doubled five files** (config.ts
  1362→2734 lines; the whole patched file embedded as a second "add whole file" section)
  while printing "Patch applied successfully". The committed version (44afb9cc, 14 files)
  was clean; the corruption came in with the uncommitted fast-default work. The embedded
  diff was rebuilt from the **official registry 1.7.1 tarball** (sha256
  `c9227a694f6de3fa79ac416b572ff986797bf6f22040c52ce229f3094395e880` — verified by
  re-download) → **19 files** (committed 14 + fast-default 2 + shutdown 3: index.ts,
  sdk.ts, shutdown-manager.ts, embedder-utils.ts). Pre-edit file preserved at
  `/var/tmp/apply-port.py.pre-per-task-deadline.20260930`.
- **Independent review (agentic_trading seat, before commit) — PASS, all re-derived:**
  own scratch `tar xzf` → `patch -p3` → exit 0, 19/19 files → `diff -r` vs live src
  **byte-identical**; second run `ALREADY_APPLIED`; pre-edit doubling reproduced
  (1372-line whole-file config.ts section; 1362+1372=2734 matches receipt exactly);
  committed 44afb9cc = 14 files; `pristine-src/` confirmed NOT pristine (stray
  `src/evidence-handoff.ts`, modified index.ts — untracked; build future patches from the
  tarball).
- **Committed + pushed `4a54e0d0`** (on top of receipts commit `91d382b2`):
  `apply-port.py` + 4 new local inventory files (`phantom-quit-repro.mts`,
  `task-deadline-check.mts`, `shutdown-timing.sh`, `upstream-issue-phantom-quit.md`).

## Open / next

- **Restart the four old-code pi sessions** — every one still arms the 35 s kill on a
  child-session quit until restarted; restart loses in-flight subagents, so idle-check
  first. PM hasn't said when yet.
- **Runbook corrections DONE (`5fdfce6b`, pushed, 2026-09-30):** §2 receipts (19-file),
  §3 phantom-quit bullet, §4 (19 files + tarball re-verify + pristine-src note),
  §5 fast-default paragraph, §6 inventory. `pristine-src/` REMOVED (PM chose delete
  over rename — name was the trap; content regenerable from tarball + apply-port.py).
  Upstream filing: PM ruled NO (2026-09-30) — `upstream-issue-phantom-quit.md` stays a
  local draft in the inventory.
- Context-400 thread (morning): see `2026-09-30_pi_context400_root_cause.md` — the
  models.json ctx fix (816e006d) is separate and unrelated to these deaths.
