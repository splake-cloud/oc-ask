# 2026-09-29 — pi-research WebGPU SEGV: whole-pi-session crashes root-caused + CPU pin applied (pi seat jett-8011)

**Symptom:** the pi session hosting the pi-research port (from fwg seat, installed
2026-09-28 ~22:06 as `@lincoln504/pi-research@1.7.1`) died repeatedly during the
port/verify missions — "the entire pi session just crashes", no stack, no JS error.

**Root cause (proven + reproduced):** the knowledge-store embedder
(`onnx-community/granite-embedding-small-english-r2-ONNX`, onnxruntime-node 1.24.3
bundled Dawn/WebGPU) SIGSEGVs in the native **process-exit teardown** on this host
(headless, Intel/lavapipe Vulkan).

- Kernel crash handler: `/var/log/apport.log` 2026-09-29 02:10:45 `signal 11` on
  `node .../pi-research/src/knowledge/webgpu-probe.mjs ...`; report
  `/var/crash/_usr_bin_node.1000.crash` (31.8MB).
- Repro 1 (probe child, exactly the packaged command): prints `PROBE_OK 384` then
  `dumped core`, exit 139 — **deterministic**.
- Repro 2 (IN-PROCESS, sacrificial child): `SESSION_OK → COMPUTE_OK dims=384 →
  DISPOSE_OK → BEFORE_CLEAN_EXIT → Segmentation fault` — even explicit
  `pipe.dispose()` does not prevent the exit-time segfault.

**Design flaw that turned it into a time bomb:** the probe judges viability by the
stdout `PROBE_OK` sentinel, NOT the exit code (the package's documented benign case
is a SIGABRT teardown abort *after* the sentinel). On this host the post-sentinel
death is a SIGSEGV → the crash was cached as **success**:
`~/.cache/pi-research/webgpu-viability.json` `{"viable": true}` (written 02:10:49,
4s after the 02:10:45 SEGV). Every pi process on the seat that later touches the
knowledge store (a `research_knowledge_search` call — AGENTS.md mandates it for
delegates at mission start — or a research run archiving a report) then loads the
WebGPU embedder in-process and **dies at quit/exit/restart** instead of exiting
cleanly. Store init is lazy ("native-free at construction"), so only knowledge-tool
users were poisoned; the store itself (`~/.pi/research/knowledge_db`, created
02:21-02:22 by gateB runs) was effectively empty → no data migration concerns.

**Why the port missed it:** the fwg patch (1,021-line inventory) never touched this
stack — `webgpu-viability.ts`, `webgpu-probe.mjs`, `embedder-init.ts`,
`embedder-utils.ts`, `embedder.ts` all byte-identical to pristine 1.7.1
(verified against `staging/pi-research-verify/pristine-src`). Host-specific native
behavior. Upstream: 1.7.2 (latest, 2026-09-27) is byte-identical in this stack —
**no upstream fix exists** (registry tarball diffed).

**Fixes applied (PM-approved, this session):**
1. `~/.pi/research/config.env` (0600, the package's own user-scope config file):
   `PI_RESEARCH_EMBEDDING_DEVICE=cpu` — first-class config, `'cpu'` = "no probe;
   always safe"; covers every pi process on the seat (TUI, headless `pi -p`,
   subagents) with no shell-env dependence.
2. `rm ~/.cache/pi-research/webgpu-viability.json` — poisoned verdict removed
   (moot under cpu; hygiene).

**Verification (verify-run deposits):**
- `verify/cpu-device-config.20260929T032413Z.txt` — installed package resolves
  `EMBEDDING_DEVICE=cpu` (DEVICE_CPU_OK, exit 0).
- `verify/cpu-store-e2e.20260929T032457Z.txt` — full store init + CPU embed
  (dims=384) + clean shutdown: `EMBED_OK → CLEAN_SHUTDOWN`, exit 0 (same process
  shape that segfaulted 139 under the webgpu verdict).

**Correct-patch vs handroll (PM asked):** the env pin = correct first-class
mitigation, not a handroll; verdict removal = reversible hygiene; the real bug fix
(fatal signal ⇒ not-viable even with sentinel + `VERDICT_SCHEMA` bump) is a local
handroll until upstream adopts it — it lives in node_modules and is wiped by
reinstall/upgrade, so if applied it must go in the port's patch inventory
(`staging/pi-research-verify/` practice) + upstream issue (my repro 2 is the
evidence they'd need). NOT yet applied.

**Open items:**
- Durable probe patch (signal rule) — not applied; PM call.
- Upstream issue to @lincoln504/pi-research (SIGSEGV-teardown variant their
  sentinel logic was designed to paper over).
- Re-test WebGPU when an upstream fix lands; then drop the cpu pin.
- `staging/pi-research-verify/ACCEPTANCE_COMMANDS.md` + gate-b recipes build env
  explicitly — they now get cpu from config.env automatically (no edit needed),
  but any recipe that wants webgpu later must set env explicitly (env > config.env).
- The Sept 28 01:07-01:45 signal-6 crash cluster in apport.log.1 is the ROOT
  seat's donsetch binary — unrelated to this incident.

Files: `~/.pi/research/config.env`, `~/.cache/pi-research/` (verdict removed),
`staging/pi-research-verify/`, crash report `/var/crash/_usr_bin_node.1000.crash`.
