# opencode drops `temperature` for OpenAI-compatible providers — fix is the `options` block

**The native `temperature` agent field never reaches a local model. Put temperature in
`options` instead, where opencode forwards it untouched.**

---

## The defect

opencode resolves the agent's `temperature` correctly and then does not put it on the wire for
`@ai-sdk/openai-compatible` providers. `top_p` and `top_k` survive the same path; only
`temperature` is lost. vLLM then falls back to the model's `generation_config.json`.

Known upstream, unresolved: issues **#25755** (reproduced with tcpdump on lo:8080 — the same
method used here), **#5037**, **#2785**, **#5674**. Present in 1.17.11 AND in 1.18.23, so
upgrading does not fix it. v1.18.19's "removed built-in Qwen sampling defaults" is a false lead —
it removes params opencode was sending, never restores one it was not.

## Proof chain (all three layers, do not skip a layer)

| layer | value | how |
|---|---|---|
| `opencode.jsonc` declares | 0.6 | file read |
| `opencode debug config` resolves | 0.6 | resolver dump |
| **wire / server receives** | **1.0** | vLLM `--enable-log-requests` + tcpdump |

The first two layers agreed and were both wrong about behaviour. **A resolver dump is not
evidence of what is sent.** Only the server log settled it.

## The fix

`temperature` is a **recognized** opencode field, so it goes through opencode's own handling
(which is broken here). Anything opencode does NOT recognize is forwarded verbatim — per the
docs: *"Any other options you specify in your agent configuration will be passed through
directly to the provider as model options."* `options` is that channel, which is why
`reasoningEffort` has always worked in this config while `temperature` silently did not.

Applied at the **model level** inside the provider block, next to `reasoningEffort`:

```jsonc
// config/opencode/opencode.jsonc
"coder38-ask":   ... "options": { "reasoningEffort": "low",    "temperature": 0.7 },   // L351
"validate38-ask" ... "options": { "reasoningEffort": "medium", "temperature": 0.8 },   // L390
```

VERIFIED on the wire against the live config, not inferred:
`coder3.8 -> temperature=0.7`, `validate3.8 -> temperature=0.8`.

The agent-level native `temperature` field was also updated 0.6 -> 0.7 for coder3.8 (L722). It is
inert, but leaving it disagreeing with what the seat actually runs is how this confusion started.

## Diagnostic recipe, reusable

1. `--enable-log-requests` on vLLM logs full `SamplingParams` per request (startup-only flag;
   `LOGREQ=1` on `launch_qwen38_27b_fp8.sh`).
2. Or `sudo tcpdump -i lo -A -s0 'tcp dst port <PORT>'` — no restart, no config change.
3. Correlate by TIMESTAMP and by which process holds the new binary
   (`readlink /proc/<pid>/exe` shows `(deleted)` for a replaced binary), or you will read some
   other client's request and conclude the wrong thing.

## ⬜ TODO — verify the :8080 prior value when the 397B is back up

**The one unverified row.** `ask`, `build` and `qwen` point at :8080 (qwen3.5-397b tri,
llama-server). That server was DOWN when the fix was applied, so "these seats were running 0.6"
rests on `scripts/launch_qwen35_397b_tri.sh --temp 0.6` — the launcher's INTENT, not the
server's behaviour. It cannot be confirmed while the server is down.

When the 397B is next up, one call settles it:

```bash
curl -s http://127.0.0.1:8080/props | python3 -c \
  "import json,sys;print(json.load(sys.stdin)['default_generation_settings']['params']['temperature'])"
```

* If it reads **0.6** → the record is correct, `ask` moved 0.6 -> 0.7 and `build`/`qwen` did not move.
* If it reads **anything else** → the in-file comments on those three agents are WRONG and must be
  corrected. `ask` did not move 0.6 -> 0.7 but from whatever that value is, and `build`/`qwen`
  (declared 0.6) silently changed too rather than staying put.

Same method that upgraded :8081 from inferred to observed (commit `ae2d05a9`): a launcher flag
shows intent, `/props` shows behaviour. Do not settle for the launcher again.

## Resolved since this card was written

* **Isolation test done.** Agent-level and model-level `options` each carry temperature
  INDEPENDENTLY — probe A (agent-level only) sent 0.33, probe B (model-level only) sent 0.44,
  both confirmed on the wire. Agent level was used for the seven remaining agents because a
  model-level entry sets ONE value for every agent on a shared provider, and `ask` (0.7) vs
  `build`/`qwen` (0.6) disagree on `qwen-ask`.
* **All nine declaring agents now send temperature** (commit `8e2b471a`). Only three actually
  changed behaviour: `coder`, `qwen-coder`, `ask`, all 0.6 -> 0.7. The other four already matched
  their server default by coincidence.
* **:8081 prior value upgraded from inferred to observed** via `/props` (commit `ae2d05a9`).

## Still open

* **Precedence untested.** Agent-level and model-level `options` each work alone; which wins when
  they disagree was never tested. Nothing in the config mixes them today.
* **:8081 not wire-verified.** That llama-server logs to a socket, so 0.7 ARRIVING there is
  inferred from the mechanism proven on :8011, not observed. Closeable with
  `sudo tcpdump -i lo -A -s0 'tcp dst port 8081'`.
* Server-side `--override-generation-config` (`TEMP=` on `launch_qwen38_27b_fp8.sh`) patches this
  port-wide but cannot serve two seats needing different values. Left UNSET — the client sends
  correctly now, and a server-side value would fight it.
