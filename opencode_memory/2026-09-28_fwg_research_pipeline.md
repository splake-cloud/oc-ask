# 2026-09-28 — fwg seat: web-research pipeline (pi-research extension + modifications) built + measured

**Session:** pi `01a0e40c-0f0c-7231-85cb-3a41805d3926` (pi-coding-agent, qwen3.8-27b-fp8,
jett-8011; workdir /data/agentic_trading; work on /home/user/seat-fwg + the `seat-fwg` container).

Builds on the 2026-09-27_fwg_sandboxed_pi_seat.md card (the seat itself). The fwg seat is a
separate, isolated seat for a different researcher (frontline-wg, clinician-researcher/podcaster)
— NOT part of the broader system; the host must not reference or index /data/seat.

## Objective
PM: give the fwg seat a fast, parallel web-research capability, then drive a full research
mission to a latency target (180s end-to-end including final synthesis).

## What was built
Research capability = the public npm extension **`@lincoln504/pi-research@1.7.1`** (installed in
the seat container's pi npm dir; `main = ./src/index.ts`, so the SDK uses `src/` directly) + a set
of **in-place source patches** (the modifications). Hand-rolled delegation was abandoned in favor
of the package + targeted adaptations.

Final architecture:
- **Explorer** = strong model (8012, `jett-8012/qwen3.8-27b-fp8`): identifies the missing inquiry
  and DIRECTS a query (directive-only — no evidence gathering).
- **Fast workers** = `jett-8081/qwen3.6-35b-a3b-q8` (llama.cpp GPU2, `-c 262144 --parallel 2`,
  ~191-207 t/s): do ALL evidence (search + fetch, 3 model responses each).
- **Immediate dependent launch:** when the explorer finishes, ONE directed fast worker launches
  immediately in the explorer's freed concurrency slot (does NOT wait for the fixed workers or a
  round boundary; max 1 follow-up, no recursive delegation).
- **Lead synthesis** = strong model (8012) final cross-territory judgment, selective-answer
  contract. Evidence-return mode + main-lead synthesis (evidence handoff; per-report citation scope).

Key adaptations (each an in-place patch, captured as a reproducible script under
/home/user/seat-fwg/patches/): explicit plan + per-researcher model routing (must survive schema
validation AND reach session creation), evidence handoff, researcher evidence-aggregation prompt,
**dependent-launch mechanism** (a real scheduler bug fixed: `await explorerPromise` before the
final `Promise.all`), **explorer directive-only** (grounding-gate exemption + validation), distinct
lifecycle telemetry, LLM_RESPONSE + synthesis-capture instrumentation, **trimmed synthesis
contract** (below).

## The latency problem (dominant cost)
Final lead synthesis was the single dominant non-overlapped cost. **Run F3 (pre-trim baseline):
total 197.389s** = evidence acquisition ~91.9s + synthesis 105.376s + post 0.09s; exactly one
synthesizer call (8,334 out-tok / 105.4s ≈ 79 tok/s, the 8012 vllm decode rate). **Thinking
resolved: `reasoning: 0`** (no reasoning tokens). The model was writing a "CITED LINKS" source
list (~41% of its output) that `ensureCitedLinks` deterministically regenerates and discards —
pure generation waste.

## The fix: trimmed synthesis contract (report-mode only)
`system-lead-synthesizer.md` modified so the lead writes **NO** source list (the appender
regenerates + appends it). Scope verified: the synthesizer prompt loads only in report mode
(`isRouter==false` → `mustSynthesize==true`, the terminal call); the evidence-return path bypasses
the internal synthesizer entirely (`assembleEvidenceHandoff`, no `callLead`). The "appended to the
final report" instruction is accurate at every call site that uses the prompt. Backup
`system-lead-synthesizer.md.bak-20260928_181339`; reproducible idempotent patch
`apply-trimmed-synthesis-contract.py`.

Verified 3 ways (no additional LLM replay needed):
- **Replay** (harness reassembles saved reports, one 8012 call, no researcher calls): baseline
  175s/138s vs trimmed 141s/89s (savings 34s/49s across 2 clean pairs; one pair discarded = 8012
  transport hiccup).
- **No-LLM local assembly check:** byte-identical determinism; 28 inline [N] preserved (none
  dropped, all in range); scraped-but-uncited URLs kept separate from supporting citations.
- **Run F4 (full mission, 132.8s)** — the real end-to-end verification.

## Measured runs (same 3-territory burnout query; scrape env is lossy — ~12 success/12 fail,
Cloudflare 403 / bot-protection / rate-limit)
- Run D **128.0s** — single 8012, no delegation (the no-delegation reference).
- Run E **370.3s** — 3-way parallel breadth works, but the explorer doing evidence tripled time
  for ~1.5× sources → evidence-per-elapsed-minute got WORSE.
- **Run F3 197.389s = the VALID pre-trim full-run baseline** (4 researchers, all complete, real
  synthesis).
- **Run F4 132.8s = the VALID post-trim full run → 180s target MET (47s margin).** 4 territories
  complete; APPEND path confirmed; 8 supporting + 6 scraped-but-uncited citations; 3,051 output
  tokens (vs 8,334 in F3).
- **Report-mode baseline (Run F4, post-trim): ~94s acquisition + ~39s synthesis ≈ 132.8s total.**
- Runs F / F2 were PARTIAL / INVALID (confounded by instrumentation bugs: TDZ ReferenceError +
  wrong variable in the explorer exemption; the 468s F2 retry is explained by the TDZ bug).

## Key decisions
- Synthesis model stays 8012. The 1-2min target was NOT achievable while 8012 does final
  synthesis pre-trim (148s > 120s) — the trim, not a model swap, closed the gap.
- Retain the strong explorer; narrow its job to identifying + directing the missing inquiry only.
  All evidence with fast workers; final judgment with the strong lead.
- Immediate dependent launch lives inside the existing orchestrator (no added supervisor layer).
- Do NOT infer token counts from characters, decode time from total elapsed, or visible-answer
  length from generated-token count. Keep scraped-but-uncited URLs separate from supporting
  citations. Do NOT present scraped-but-uncited URLs as supporting citations.

## Portability (asked this session)
- **Package:** portable (public npm `@lincoln504/pi-research@1.7.1`, registry.npmjs.org).
- **Modifications:** portable ONLY as the 13 patch scripts in /home/user/seat-fwg/patches/ (all
  `apply-*` hardcode the container path `/root/.pi/agent/npm/node_modules/...`; tied to 1.7.1
  source — a different SDK version may not accept them).
- **Launch harnesses + model specs:** seat-specific (fwg burnout query + jett-8081/jett-8012);
  /data/agentic_trading has its own models.json — would need a new harness.
- Pulling the pipeline into /data/agentic_trading is a **scope decision** (the fwg seat was
  deliberately isolated from the main system). Offered to parameterize the patch scripts (path +
  SDK version as args) for cross-seat reuse.

## Files
- Patches (reproducible): `/home/user/seat-fwg/patches/` — apply-dep-launch.py, apply-directive-only.py,
  apply-dep-telemetry{,2,3}.py, apply-explicit-plan.mjs, apply-evidence-handoff.py,
  apply-researcher-prompt.py, apply-response-capture.py, apply-synthesis-capture.py,
  apply-tool-schema.mjs, apply-trimmed-synthesis-contract.py, depschedule-stub.cjs,
  replay-synthesis.ts, assembly-check.ts, launch-runF4.ts.
- **Trim record:** `/home/user/seat-fwg/analysis/SYNTHESIS_TRIM_RECORD.md` (baseline 197.389s
  retained; replay savings recorded separately; 180s status).
- Run outputs: container `/workspace/outputs/fwg_runF4_*` + host `/home/user/seat-fwg/analysis/fw_runF4_*`.
- SDK live (in-container, NOT in git): `/root/.pi/agent/npm/node_modules/@lincoln504/pi-research/src/`.
- Env (container, persistent): PI_RESEARCH_SCRAPE_TIMEOUT_MS=6000,
  PI_RESEARCH_MAX_EVIDENCE_INPUT_BUDGET_CHARS=150000, LLM_THINKING_LEVEL=off,
  SYNTHESIS_MAX_TOKENS=32768, PLANNING_MAX_TOKENS=16384, LLM_TIMEOUT_MS=300000, LLM_MAX_RETRIES=2.

## Open / next
- **Dockerfile.seat NOT rebuilt** — all patches are in-container only (ephemeral); a rebuild bakes
  them in (needs a go).
- Run the PM's actual question ("moral injury men vs women") through the validated pipeline.
- Option B (donsetch + delegation/budget fixes) — not started.
- Minor: model leaks ~2,400 chars of inline URLs in prose (redacted by `redactUnverifiedProseUrls`);
  strengthen the "no bare URLs in prose" clause if it recurs.
- Run E synthesis-retry cause still open (the 468s F2 retry is explained by the TDZ bug; the E
  retry is not).
- 8081 `n_parallel=2` means a 3rd concurrent 8081 researcher queues at the model-server level.
