# 2026-08-25 — qwen3.6 coder: bounded thinking (--think-budget), and how NOT to probe it

PM wanted "a tick up in thinking/reasoning" on the :8081 coder slot and was considering
min_p 0.0 -> 0.05. Both premises were wrong; the real lever is a reasoning-token budget.

## Why min_p was the wrong lever (twice over)

- **min_p is a truncation filter, not a deliberation control.** It drops tokens below
  `min_p x P(top token)`. RAISING it makes the candidate pool SMALLER and the output more
  conservative. It cannot add reasoning — it removes options. Both Qwen presets specify
  min_p 0; the launcher records "min_p 0, never greedy" as doctrine.
- **Reasoning was OFF at the server.** The live args carried `--reasoning off` (qwen3.6 is
  thinking-by-default; the launcher disables it because this slot is the QUICK lane). No
  sampling number produces thinking traces while that flag is set.

## The real lever

llama.cpp (build 408ae2b) supports `--reasoning-budget N` with **N>0 as a token budget**
(-1 unrestricted, 0 immediate end), plus `--reasoning-budget-message MSG` injected before
the end-of-thinking tag when the budget is exhausted. That is the point between "off" and
"deep thinking".

`scripts/launch_qwen36_35b_q8.sh --think-budget N` (added `edbdfcd5`) implies `--think`,
so it also switches to the vendor THINKING preset temp 0.6 / top_p 0.95. Validation rejects
non-positive N — llama.cpp reads 0 as "stop thinking immediately", so an unchecked 0 would
silently do the OPPOSITE of what was asked. The close message always sends: a bare cap
guillotines the thought mid-structure, the likeliest way to corrupt a tool call.

Same commit fixes a latent bug: `GUARD_GPU="${CUDA_VISIBLE_DEVICES%%,*}"` expanded before
the `${GUARD_GPU:-0}` fallback, so under `set -u` the launcher died whenever the var was
unset — it only ever ran via llm-alloc.

## Log markers (this is how you observe it — reusable)

`/tmp/llm_alloc/<name>.log` carries an explicit vocabulary:

```
reasoning-budget: activated, budget=256 tokens
reasoning-budget: budget exhausted, forcing end sequence
reasoning-budget: forced sequence complete, done
reasoning-budget: deactivated (natural end)
```

`budget exhausted` vs `deactivated (natural end)` is the whole diagnostic — it tells you
whether the cap bound WITHOUT needing to inspect answers. Note `grep -E '...|invalid|...'`
matches the routine `erased invalidated context checkpoint` lines; exclude them.

## Measured, 2026-08-25 (PM-supervised, single-shot Q&A — NOT agentic tool loops)

- 8 budget exhaustions, 2 natural ends, 0 errors, clean under 2 concurrent slots.
- At the cap: 1.39–1.86 s of thinking; close cost 67–85 ms.
- Natural ends: 391 ms and 398 ms.
- **Thinking length is BIMODAL** — ~400 ms natural end, or straight to the cap, nothing
  between. So 256 is either irrelevant or binding, never a bound requests finish just under.
- **Every capped answer checked was CORRECT**, including a 5-leg P&L accumulation chain
  (sign inversion on 2 shorts, ~20 dependent steps) answered exactly right with its
  reasoning truncated mid-chain.
- Tool calls under bounded thinking: clean `tool_calls`, correct name/args,
  `finish_reason=tool_calls`, nothing leaked into `content` — including on the truncated run.

Verdict: keep 256. Bounded deliberation at ~1.5 s/call with no observed quality cost.

## Probe-design lessons (2 of 4 probes were DEFECTIVE — this is the durable part)

- **Recall contamination.** "Count 2024 trading days" -> 252 was answered correctly, but 252
  is the canonical NYSE figure the model has memorised. Passing proved nothing. The
  *easier* non-anchored probe (74 trading days over a partial range) is the one that
  exposed a real error. **A probe with a famous answer is not a probe.**
- **Ambiguous wording reads as a model failure.** "Commission $0.65 per contract per side,
  both entry and exit" says the same x2 TWICE; the model applied x4. That looked like a
  reasoning failure and was a prompt defect. Re-run with "charged once on the opening trade
  and once on the closing trade" and fresh numbers -> exactly correct, under the cap.
- **Design so a wrong answer is unmistakable.** Make winners/losers nearly cancel, so a
  single sign error lands far from the target rather than plausibly near it.
- **Run the re-test in a FRESH session** or the model self-corrects from the prior exchange
  in context and you learn nothing.

## Falsified hypothesis (recorded so it is not re-proposed)

I claimed "truncation destroys carried state but preserves re-derivable structure", built
from the ordering puzzle passing while the P&L chain failed. **Wrong** — the P&L chain
failed on my wording, and when re-run cleanly it survived truncation intact. Carried state
is not the vulnerable thing.

## The error that WAS real, and its actual fix

One genuine model error: an inclusive-date fencepost (73 vs 74). It happened with reasoning
INTACT — the cap never fired — and self-corrected when asked to verify. That class is a
**verification-discipline gap, not a budget gap**; no budget value fixes it. The lever is
putting verification into the FIRST turn (AGENTS.md already carries
`CLAIM | VERIFY METHOD | PROOF` and the envelope's mandatory VERIFICATION field).

## Open

- Everything above is single-shot Q&A. The delegate lane does multi-turn tool loops with
  growing context (log was at ~14.8k tokens). Bounded thinking across a long agentic chain
  is UNTESTED — real delegation work will settle it, probes will not.
- Commits: `edbdfcd5` (launcher), `32d3f2f1` (tune_registry entry + scoped evidence),
  both on market_data master.
