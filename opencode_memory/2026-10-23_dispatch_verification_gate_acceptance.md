# Dispatch verification gate — acceptance phase, boundary fix, research_agent deployment

**Session:** pi seat `01a16676-0b63-74be-808f-5e7d873a8675` (jett-8012 / qwen3.8-27b-fp8), 2026-10-23.

## What was built

The `dispatch-verification-gate` extension (AT: `.pi/extensions/dispatch-verification-gate.ts`) got its **acceptance phase** on top of the earlier BUILD core (token tagging + lifecycle correlation), per contract `/tmp/dispatch_gate_contract_20261022.md` with `scripts/check-dispatch-verification.py` as the executable schema spec:

- Checker-compatible state objects (schema_version=1, mission, deliverable, artifact_sha256, clauses, failure_conditions, delegate_verification) written per transition to `/tmp/dispatch_gate/<dispatch_id>.state.json` (atomic tmp+rename); envelope parsed from the dispatch prompt (DELIVERABLE/MISSION/SPEC/FAILURE_CONDITIONS).
- `dispatch_accept` tool: settlement check (state must be RETURNED_UNVERIFIED+completed) → runs the real checker → ACCEPTED only on checker PASS (artifact hash re-checked → tamper rejected).
- `dispatch_fail` tool: main-seat adjudication (FAILED + adjudicated + reason).
- UNREGISTERED records for tracked-type subagent events without a dispatch token (can never be accepted).
- **Boundaries (fail-closed reading, documented in file header):** save/freeze bash calls blocked AND agent_before_settle forced-continues while any tracked dispatch is not accepted-or-adjudicated (DISPATCHED, RETURNED_UNVERIFIED, FAILED-unadjudicated). A reviewer caught that the first cut excluded RETURNED_UNVERIFIED from both boundaries — fixed; a returned result can no longer pass either boundary.
- **Per-seat config surface:** `<cwd>/.pi/dispatch-gate.json` {tracked, checker, gateDir, savePatterns} with AT defaults when absent; explicit AT config committed.

## Key facts settled

- pi 1.3.0 API: tool_call events carry `event.input` (mutable), NOT `details`; `pi.sessionManager` is undefined in handlers — use the handler's `ctx.sessionManager`. `agent_before_settle` honors `continue: true` only when the boundary context can continue — returning a `custom_message` entry alongside `continue` is what makes it work (last message must not be assistant).
- `typebox` (pi's dep, v1.3.27) is resolvable from project extensions at runtime via jiti's base fallback, but NOT from plain node — harness needs a `node_modules/typebox` symlink in the repo (gitignored).
- Each headless `pi -p` run writes **two** session files (shadow + real); the real one contains the custom entries. `pi -p --session-id <id>` resumes a specific session headlessly (rebuild-from-branch works; dispatch_accept/dispatch_fail find rebuilt dispatches).
- Live proofs (all this session): foreground dispatch→resume→acceptance `ACCEPTED adecb7e7…`; background run: settle-continue woke the model twice, then the model ran the FULL acceptance protocol autonomously → `ACCEPTED b6e6a49f`; tamper → `REJECTED artifact hash mismatch`; dispatch_fail live on a resumed session.
- Model-loop incident (context): the session reviewed at the start (01a1666d) looped on tsc verification 12+× under qwen3.8-27b-fp8-instruct; server was healthy — model-side termination failure, cross-model phenomenon, not a routing verdict.

## research_agent deployment (items 2–5 of the port plan)

- Deployed byte-identical extension + `scripts/check-dispatch-verification.py` + `scripts/verify-run-receipt` to `/data/research_agent/`; config tracks `fast-coder`, `semantic-worker`, `semantic-worker-long` (builder_agent deliberately untracked — PM can add); `savePatterns: ""` (no save script there; settle boundary still applies).
- AGENTS.md gained a "Dispatch verification gate" section (envelope format + accept/fail protocol + boundaries). Live test: headless main seat read the section and ran the full acceptance protocol unaided → `ACCEPTED ef5759ff`.
- research_agent dispatches use the `Agent` tool (@tintinweb/pi-subagents, host config) — mechanism verified compatible; the `agentScope` args in its dispatch-integrity section are tolerated extras.

## Published

- AT `origin/master`: `ed6e74fa0` (extension + AT config); earlier this session `44a8522c2` (checker + receipt), `ab659102a` (boundary fix).
- research_agent `origin/master`: `99fb405f` (5 files, verified blob-identical; push diff vs pre-push origin = exactly the gate section + deployed files).

## Open / next

- **fwg + pax seats:** blocked on the delegation-mechanism decision — they run a different `subagent` tool (no `subagents:*` events). Option (a) migrate to @tintinweb/pi-subagents, or (b) write an adapter for that tool's lifecycle. Their pi homes are `/data/seat/{fwg,pax}/piagent` (bind-mounted into the containers; host-side file drop works, no image rebuild).
- `fast-coder` lane's model (jett-8081 / qwen3.6-35b-a3b-q8) is 404ing — tracked dispatches will record FAILED until restored.
- RETURNED_UNVERIFIED live-settle case: harness-proven only (the live run was aborted by the user); mechanism itself live-proven for DISPATCHED.
- TUI enforcement: UNVERIFIED (not scriptable; same hook path as headless).
- Harness: `/tmp/dvg-test/test2.ts` (53 checks; `DVG_EXT` env selects the extension under test). Scratch under `/tmp/dvg-live/`, `/tmp/dvg-ra/`, `/tmp/dispatch_gate/`.
