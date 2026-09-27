# pi-repetition-guard — local fork: over-fire + run-kill fixed (2026-09-27)

PM reported two issues with `npm:@capdiem/pi-repetition-guard`: (1) fires too
frequently, (2) when it fires the run is killed and needs a manual resume.
Both root-caused from source (the package ships a source map with the full
TypeScript) + fire history in `~/.pi/agent/sessions`; fixed with a local fork;
npm package fully removed.

## What was built/decided

- Fork at `~/.pi/agent/extensions/pi-repetition-guard.ts` (single file, auto-
  loaded user extension; same model/behavior otherwise, incl. `/runaway`
  toggle). Built by qwen38-collab (jett-8011) from the spec; verified by me.
- Replay acceptance fixture: `tools/test_pirg_replay.ts` (committed
  717622a8, master). Run: `node tools/test_pirg_replay.ts` → 13/13.
- `npm:@capdiem/pi-repetition-guard` removed via `pi remove` (gone from
  settings, npm/package.json, node_modules).

## Root causes (key facts)

**Issue 2 — run kill (the important one).** The guard calls `ctx.abort()`
then sends its corrective steer at `message_end`/`agent_end` via
`sendUserMessage(steer, {deliverAs:"steer"})`. At that moment the run is still
streaming, so pi only QUEUES the steer. But the session's post-run
auto-continue check is `!agentRunAbortRequested && hasQueuedMessages()`
(pi dist/core/agent-session.js `_handlePostAgentRun`) — the guard ITSELF
requested the abort, so auto-continue refuses; the steer strands until the
user manually resumes (TUI `agent.continue()` drains the steering queue when
the last message is assistant — that's the "manual resume" the user did).
Fix: deliver the steer from `pi.on("agent_settled")` — when idle,
`sendUserMessage` triggers a FRESH turn (auto-resume with the corrective
message); if a run is somehow already in flight it degrades to a queued steer
(no throw). Abort itself kept (ADR 0002 active-intervention by design); only
the delivery point moved.

**Issue 1 — over-fire.** 13 historical fires, 10 false positives:
- 8 from the near-dup (variation-loop) detector: whole-message short-segment
  dominance ≥0.9 fired on legitimate structured thinking (47-item card-name
  list, citation lists, two similar code blocks quoted for comparison,
  "Let me reconsider…" deliberation). All FPs had ≤6 near-dup clusters and no
  tail concentration.
- 2 from the tape (exact-periodic) detector: P=30 period units made of
  spaces/newlines only (trailing padding in otherwise healthy messages,
  distinct non-ws chars = 0).
- 3 true positives (exact 2× re-emission of 384/1667/2369-char blocks).
Fork tuning: tape — skip period units with <8 distinct non-whitespace chars
(`MIN_PERIOD_DISTINCT_CHARS`); near-dup — TAIL-CONCENTRATED: last 15 short
segments only, need ≥8 segments, dominance ≥0.95, largest cluster ≥4.

## Collateral finding: settings.json was invalid JSONC

`~/.pi/agent/settings.json` had `//` comments, but pi 0.87.1 parses settings
with plain `JSON.parse(stripBom(...))` (bundle chunk:
`settings2=JSON.parse(stripBom(content))`) — no comment stripping. The file
was silently falling back to `{}` (all settings incl. `packages` and
`steeringMode:"all"` ignored; a "Invalid settings file" warning appears on
every launch). Fixed: rewrote as clean JSON (same keys/values as intended).
NOTE: `steeringMode:"all"` is now actually in force (was default
one-at-a-time until this fix).

## Verification

- `verify/pirg-fork-exports.20260927T113105Z.txt` — node imports the fork,
  all named exports present.
- `verify/pirg-replay.20260927T113112Z.txt` — 13/13 archived-fire replay.
- E2E auto-resume (session `--tmp--/2026-09-27T11-32-39-…jsonl`): forced
  verbatim line-repetition via `pi -p`; session shows user(prompt) →
  assistant(aborted) → user(自动护栏 steer) → assistant(aborted) →
  user(steer retry 2) → assistant(aborted) → compact-give-up — the full
  retry budget (2 steers + compaction) ran with ZERO human input in
  non-interactive mode. Old code would have stranded the first steer and
  exited after the first abort.

## Notes / open

- Delegate spec typo caught by qwen38-collab: the 09-22 session basename in
  the mission had a UUID tail borrowed from the 09-21 file; the fixture uses
  the real basename (`…01a0cb78-fe1f-75d2-9d64-552d512fab26.jsonl`).
- jett-8081 (qwen-coder) was DOWN during this session (host-verified
  000); the build was dispatched to qwen38-collab (:8011) instead.
- Upstream (capdiem) should get the two fixes (steer at agent_settled;
  tail-concentrated near-dup + distinct-char tape gate) — not filed yet.
- The local `loop-guard.ts` (separate, steer-only, calibrated 2026-09-14) is
  unchanged and coexists fine.
