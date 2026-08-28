# Qwen3.8 post-reboot restore + latency decomposition — what is tunable and what is not

Reboot 2026-08-28 ~17:39. PM: *"drop qwen 3.5 from the tricard and load the qwen 3.8"*, then
*"i am still in flight on work that hte 3.8 has to finish before i go back to tri card but i
still plan on doing so"*, then on the 3.8's behaviour: *"validate38 is still slower than i would
like but tolerable. coder is not as fast as 3.6 but its quality is measurably better"*.

## What was done

`ik-llama-server.service` (user unit, **still enabled**) fired at boot and the qwen3.5-397b tri
claimed all three cards, so the 3.8 had nowhere to land. Restore is **two commands, ~1 min**:

1. `systemctl --user stop ik-llama-server.service` — clean; kills only the tri (it is the unit's
   cgroup). Do **not** use `llm-alloc`'s `evict_gpu` — it SIGTERMs every pid on the card.
2. `setsid nohup bash scripts/launch_qwen38_27b_fp8.sh > logs/qwen38_launch_wrapper.log 2>&1 < /dev/null & disown`
   — **bare, no env vars**: the launcher's code defaults *are* the wanted dedicated-gpu2 slot
   (`:8011` gpu2, CTX 262144, UTIL 0.90, KV fp8). Healthy in **45 s**.

KV pool came back at **1,504,032 tokens** — the exact 2026-08-27 measured figure, so the
dedicated slot reproduces.

**PM HOLD:** the 3.8 keeps gpu2 until the in-flight work finishes. The tri return is **planned,
not cancelled**, so `ik-llama-server.service` **stays enabled** — do not disable it and do not
re-propose disabling it. Cost is that any reboot before then lands back in the state above.

## Boot-unit facts corrected

* **`qwen36-coder.service` now exists (user, enabled) and self-started correctly** on `:8081` at
  ctx 262144. This supersedes the older "the coder is the only thing missing after a reboot".
* **The 3.8 has no boot unit, deliberately** (stated in its launcher header) — it is now the one
  manual post-reboot step.
* RAG served the **small root** (0.6b, gpu1, `verifier_kb_small`). Deliberate, not a reboot loss:
  the full-root drop-in was renamed `full-root.conf.off` on 2026-08-21 and systemd reads only
  `*.conf`.

## Latency decomposition — measured live from `:8011/metrics`, 45 completed requests

0 errors, 0 aborts, 0 length-truncations, 0 repetition.

| metric | value |
|---|---|
| mean prompt | 55,407 tokens |
| mean TTFT | **1.47 s** |
| mean output | 519 tokens |
| mean e2e | 7.13 s |
| derived decode | **~92 tok/s** |
| prefix cache | **91.1%** (1,800,000 / 1,975,205) |
| `num_requests_waiting{reason="capacity"}` | **0** |

Spec-decode per-position acceptance **0.848 / 0.715 / 0.599** against the 0.84 / 0.73 / 0.62
measured 2026-08-27; mean accepted length 3.16 (documented range 2.80–3.18). The MTP head
reproduces its old curve.

**Latency is fully explained by output length. There is no knob-shaped variance left.** The two
distributions line up nearly one-to-one: 7 requests generated >1000 tokens; 8 took >10 s. The
longest (30–40 s bucket) works out to ~3,000 tokens at 92 tok/s. Decode sits at the hardware
plateau and TTFT is near-free, so the only remaining term is token count.

ctx 262144 is doing nothing for the current workload — mean prompt is 55k, a fifth of it.

## coder3.8 slower than 3.6 is ARCHITECTURAL, not a config

qwen3.6-35b-a3b is an MoE with **~3B active** parameters per token. Qwen3.8-27B is **dense — 27B
active**. Roughly 9x the arithmetic per decoded token. No serving config closes that gap, and the
quality difference has the same root cause. Stop hunting for a knob; the speed is the price of
the quality.

## Two stale-doc corrections (I had both wrong in-session before checking)

1. **Temperature IS on the wire.** The launcher's `TEMP` env-var note — "opencode resolves a
   per-agent temperature but does NOT put it on the wire" — describes the **pre-fix** state. Fixed
   2026-08-27 via the `options` channel (see `2026-08-27_opencode_temperature_options_passthrough.md`).
   Both seats carry model-level `"options": {..., "temperature": N}` in
   `config/opencode/opencode.jsonc`: **coder38-ask 0.7**, **validate38-ask 0.8**, wire-verified.
   `generation_config.json`'s `temperature: 1.0` is only the fallback when the client sends
   nothing — and the client sends. The server was launched bare (no `--override-generation-config`),
   which is correct and not a defect.
2. **validate38-ask is already at `reasoningEffort: "medium"`**, set 2026-08-24 at PM direction
   ("drop the reasoning effort to med"), **not** xhigh. The comment above `coder38-ask`
   ("To get xhigh, OMIT the field — see validate38-ask below") is now misleading: validate38-ask
   does not omit it. Getting xhigh back means REMOVING the line.

## Flagged, NOT corrected — stale preconditions in `scripts/launch_qwen38_27b_fp8.sh`

Two blocks read as unconditional prohibitions but carry an unstated sizing precondition:

* **"TWO SEATS: MEASURED, DO NOT"** — two ~120k seats thrashing, hit rate 78.4% → 35.8%.
* **"RULE: pick ONE reasoning_effort per session"** — prefix variants evicting each other,
  ~50 s re-cold-prefill.

Both were measured on the **co-resident gpu0** slot at a **~162,415-token** KV pool. The dedicated
gpu2 pool is **1,504,032** — **9.3x**. Two ~120k seats were 148% of the old pool; they are 16% of
this one. The mechanism behind both warnings is pool pressure, and the pressure is gone — which is
consistent with the PM's report that both seat configs behave as expected, and with the live 91.1%
hit rate (flatly inconsistent with the 35.8% thrash figure). **Not retested. Flagged for a PM
decision, not edited.**

## Open / next

* **validate38 "slower than I'd like but tolerable"** — the effort lever is largely exhausted. It
  is already at `medium`; the only step down is `low`, which `opencode.jsonc` documents as risky
  (brevity instruction risks under-reasoning a hard verdict, and per a community A/B can *increase*
  tokens on hard tasks via loops). Note the config also states **NOT ESTABLISHED: whether effort
  actually changes thinking LENGTH** — a single-sample check came out non-monotonic (low 616 /
  medium 373 / omitted 260 chars). Do not assert effort explains validate38's token count.
* **Per-seat attribution is not possible from `/metrics`.** Both seats share `:8011` and the served
  model name, so all counters are aggregate — the "long-output tail is the validator" reading is
  inference, not measurement. `LOGREQ=1` (`--enable-log-requests`) would separate them by
  SamplingParams (temp 0.7 vs 0.8) but requires a restart, so it was not run against live work.
* **`opencode_memory` FORKED IN TWO (found this session) — bidirectional, both live.** Not a
  stale copy and not a symlink (different inodes):
  * `/home/user/oc-ask/opencode_memory/` — canonical per `AGENTS.md`; 31 files; git repo
    `git -C /home/user/oc-ask` (remote `splake-cloud/oc-ask`). **29 cards exist only here.**
  * `/data/agentic_trading/opencode_memory/` — 11 files, no `README.md`; tracked in the
    **agentic_trading** repo. **8 cards exist ONLY here**, including
    `2026-08-27_iron_fly_100w_economic_baseline.md` (the CANONICAL frozen baseline card),
    `2026-08-27_opencode_temperature_options_passthrough.md` (cited above), `_v0_baseline_gate`,
    and the L1-B / L1-D / L1-E study results.
  * Both `INDEX.md` files differ. Each side is blind to the other's cards.
  * **Origin: 2026-08-27.** `git log --diff-filter=A -- opencode_memory/` in agentic_trading shows
    the copy was created that day (6 commits, first `bcb54104`) — a seat working with cwd
    `/data/agentic_trading` resolved the memory path **relative to its own cwd** instead of the
    `~/oc-ask/opencode_memory/` that `/data/agentic_trading/AGENTS.md` actually names, and the
    research commits swept the new directory into the project repo.
  * **NOT reconciled — PM decision.** Merging spans two git repos with independent histories, and
    the 8 orphans include a card other studies treat as canonical. This card was filed on the
    `~/oc-ask` side.
