# 2026-09-29 — SPX verticals research: GATE-B CONTRACT VIOLATION + routing audit (pi seat jett-8011)

**Session:** `01a0ebc0-eb34-7537-a8c5-9a369789f221`
(`/home/user/.pi/agent/sessions/--data-agentic_trading--/2026-09-29T06-01-24-020Z_01a0ebc0-eb34-7537-a8c5-9a369789f221.jsonl`)

## What actually went wrong (audited 09/29 by the 8012 seat; claims verified here)

**The SPX-verticals research run violated the pipeline contract.** My `research`
call arguments were exactly `['query', 'depth']` (verified from session JSONL,
line 7) — no `researchers[]`, no models, no explorer. The contract (runbook
`docs/model-kb/pi_research_port_runbook.md` §5 + memory card
`2026-09-28_fwg_research_pipeline.md` + `staging/pi-research-verify/gate-b-prompt.txt`)
requires explicit `researchers[]` on EVERY research call: 2–3 evidence
territories on `jett-8081/qwen3.6-35b-a3b-q8` (fast) + ONE directive-only
explorer on `jett-8012/qwen3.8-27b-fp8`.

Proof of the violation (all verified against sources):
1. Call keys = `['query', 'depth']` only — session JSONL.
2. `/tmp/pi-research.log` run window 06:01–06:12: **zero jett-8081 LlmUsage
   entries** (last 8081 use 02:22, different session); llama-server healthy and
   idle the whole time. All 3 auto-decomposed researchers ran on 8012.
3. Result: 8m16s for the same 3-territory shape validated at **132.8s** (Run
   F4). 8012 did the evidence work the design assigns to 8081. The SPX answer
   itself is usable but must NOT be presented as pipeline-validated.

**My first audit (this session) was on the wrong layer.** I proved the
`PI_RESEARCH_MODEL=jett-8012/...` pin in `~/.pi/research/config.env` is
working (log 06:03:06: `jett-8012/qwen3.8-27b-fp8`, raw response
`"provider": "jett-8012"`) and blamed the bare-model-id report footer for the
"8011 everywhere" impression. That was correct but secondary: the pin only
governs the DEFAULT; the real defect was a call with no `researchers[]`, which
no default can rescue. The footer still hides the provider (cosmetic fix
candidate), but the routing layer is where the contract lived and was broken.

**Why it was invisible from inside the session:**
- The `research` tool schema makes `researchers[]` optional; a minimal call is
  schema-valid and directive-compliant (8011 avoided) while breaking the design.
- AGENTS.md said nothing about research routing; the runbook/memory card/
  gate-b template are not auto-loaded; the RAG/knowledge store holds domain
  cards, not the pipeline contract — so the mandated pre-flight couldn't
  surface it.

## Fixes applied (this session)

- **AGENTS.md §"Research pipeline routing" ADDED + committed**
  (`19a0950e`, Agent-Print pi-jett-8011): explicit `researchers[]` mandatory on
  every research call; seat map; gate-b template pointer; defective-run rule.
  This is the surface every seat actually auto-loads.

## Named, not applied (need PM go)

1. **Resolver default patch** (port event per runbook §5): auto-decomposed
   researchers default to 8081, 8012 reserved for explorer/router/lead — so a
   bare call degrades gracefully instead of silently. Needs PM approval +
   Gate A re-run; script home `/home/user/seat-fwg/patches/`.
2. **Re-run the SPX-verticals query under Gate-B routing** to regenerate the
   answer on the designed pipeline (cost: one ~2-min run).
3. Cosmetic: report footer prints provider/model, not bare model id.

## Other anomalies noted (not the incident)

- Knowledge-triage attempt 1/3 at 06:03:06 hit stopReason `length` (2048 out-tok
  all thinking, no JSON → auto-retried). Thinking budget vs output cap mismatch.
- Pre-pin runs today 04:11–04:39 genuinely hit jett-8011 (before the 05:14
  config write / other seat) — the original "all 8011" impression likely came
  from those.
- 8 Cloudflare failures in the run (expected; recorded in retrieval inventory).
