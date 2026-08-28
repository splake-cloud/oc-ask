# 2026-08-27 — SQLMesh weekly-IV substrate: M1 bounced at Gate-1, root cause = workdir output-token cap

**Session:** `ses_fbdeafe80ffe0V9oJg4sDVsmlG` (opencode, coder3.8 seat). Recovered from
`~/.local/share/opencode/opencode.db` (`session_message`/`part` tables) after context-limit cut.

## What it is

Building the **weekly IV substrate** — the iron-fly conditional-entry (L1) data dependency —
through the SQLMesh agent's four-gate machine:
Gate-0 spec intake → Gate-1 builder → Gate-2 certification → Gate-3 guarded execute.

Two models, hard-ordered:
- **M1** `iv_weekly_state_daily` — INCREMENTAL_BY_TIME_RANGE (time_col `trade_date`, lookback 3), build 2022-06-01→2026-12-31, test_window 2024.
- **M2** `iv_weekly_percentile` — FULL, depends on M1 (hard-gated: M1 must be promoted before M2 dispatch).

## Where it stopped — M1 bounced at Gate-1, twice, zero artifacts

| Dispatch | Session | Result |
|---|---|---|
| 19:37 (original) | `ses_fbb56b01cffeynXs1Zs63WTy3z` | 19 msgs / 1131s, last `finish:length` @ 16000 out. Completed all verification (Pin-4 cross-check, holiday mapping, spine counts), was *about to write the model* when truncated. |
| 21:31 (hardened re-dispatch) | `ses_fbae1742effeeVWe7Mot7V7p08` | 9 msgs / 290s, last `finish:length` @ **16000 out**. Burned budget on reasoning (msg7=4874, msg8=16000) after reading 2 files, never wrote the artifact. |

Both bounces correctly returned `rc=3, outcome=artifact_failure` (not the old silent `ok`)
because the D1 fix (artifact-contract gate) was already deployed and working.

## Root cause (found in the final in-flight lookup when cut off)

**`/var/tmp/oc_sqlmesh_builder/opencode.json:17` → `"output": 16000`.**

The builder **workdir config shadows the global**. Global `opencode.jsonc` gives
`qwen3.8-27b-fp8` `output: 32768` (lines 355/391), but the workdir seat pins it to **16000**.
Qwen3.8 is reasoning-verbose (`reasoningEffort: medium`), so it spends the entire 16000-token
output budget thinking and is truncated before emitting model+test+receipt. **Same defect class
as the first bounce — not a separate "early-stop."** The model isn't stopping on its own; it's
being cut off mid-generation. `oc_dispatch.py` preflight resolves config via
`GET /config?directory=` (workdir shadows global) — confirmed in `oc_dispatch.py:88-98`.

## On-disk state (verified, matches the cut-off)

- Specs: `.ai/inbox/build_spec_iv_weekly_{state_daily,percentile}_gate0.md` + envelope
  `build_spec_iv_weekly_substrate.md` (470 lines, §0 template shape). **Gate-0 passed for both**
  (transcripts `verify/gate0_M1_verify.*`, `gate0_M2_verify.*`, plus the earlier p2 runs).
- Hardened prompt staged: `.ai/packets/iv_weekly_state_daily/dispatch_prompt_m1_hardened.md`
  (embeds pre-verified A1–A9 + KAS facts so the builder transposes instead of re-exploring).
- Workdir quarantined of stale iron-fly deposits (25/25 moved, manifest written).
- D1 (artifact-contract gate in `dispatch_sqlmesh_builder_gated.py`) + D3 (workdir `sqlmesh.yml`)
  deployed and verified (`verify/d1_dispatcher_tests.*`, `verify/m1_redispatch_preflight.*`).
- **No** `iv_weekly_state_daily.sql` / KASA test / receipt anywhere — M1 still needs a successful Gate-1.

## Defects catalogued in the session (D1–D5)

- **D1** (FIXED): gated dispatcher reported `outcome:ok` on Gate-0 pass without checking artifacts
  → a truncated/no-op dispatch was indistinguishable from success. Now fail-closed artifact gate.
- **D2** (FIXED): stale shared-workdir contamination (iron-fly v1 receipt/model in the seat checkout).
- **D3** (FIXED): workdir lacked `warehouse/sqlmesh.yml` → `@VAR` tokens unresolvable in-workdir.
- **D4** (FIXED): stale reference model in workdir (v1, not the v2 the spec says to mirror).
- **D5** (root cause of the token-burn): prompt was a pure transposition brief with no pre-verified
  data context → builder re-did all pool exploration and burned the output budget. Hardened prompt
  addresses this; the **16000 cap** is the remaining blocker.

## Open decision (was about to lay out when cut)

Three ways to clear the 16000-cap truncation before re-firing M1 Gate-1:
1. **Raise workdir cap** to 32768 (align with global) — `opencode.json:17`.
2. **Lower `reasoningEffort`** `medium`→`low` in the same file.
3. **Both** (recommended) — raise cap *and* trim verbosity for headroom in one dispatch.

Holding for PM ratification per the standing rule (report, stop, options + recommendation,
no silent fixes).

## Next

Apply the chosen cap/verbosity fix to `/var/tmp/oc_sqlmesh_builder/opencode.json`, then re-fire
the hardened M1 Gate-1 dispatch:
`python3 scripts/dispatch_sqlmesh_builder_gated.py --spec .ai/inbox/build_spec_iv_weekly_state_daily_gate0.md --expect-model warehouse/models/iv_weekly_state_daily.sql --expect-test tests/test_warehouse_iv_weekly_state_kasa.py --expect-receipt BUILDER_RECEIPT.candidate.json --expect-table iv_weekly_state_daily`
(verify `--agent sqlmesh-builder` is forwarded — a prior re-fire dropped it and ran as default `ask`).
On success → Gate-2 certification → Gate-3 guarded execute (dev, then PM-token prod) → then M2.
