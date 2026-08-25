# 2026-08-25 — Does the 3.8 coder fit co-resident with the tri-card 397B + RAG?

PM question, asked in two steps: *"does the 3.8 coder seat sit co resident with the
tricard 3.5 if the 3.6 is not loaded"* → then narrowed to *"it would be a world where
its tricard, 3.8 coder, rag"*.

**Answer: yes.** That three-way is the configuration `scripts/launch_qwen38_27b_fp8.sh`
was written for — its bare defaults ARE the co-resident sizing. No card in that world
holds a load it has not already been measured holding.

## The per-card budget (each card 97,887 MiB)

| | gpu0 | gpu1 | gpu2 |
|---|---|---|---|
| 397B tri `--tensor-split 25,37,38` | 53,884 | ~81,627 | ~79,582 |
| Qwen3.8-27B-FP8, `UTIL=0.40` | 39,155 | — | — |
| small RAG `--device gpu1` | — | ~6,038 | — |
| **idle free** | **~5,930** | **~9,946** | **~18,305** |

Box-wide that leaves ~34 GiB idle. The tri rows are DERIVED (card total minus the
measured free), not separately measured; the free row is measured.

### Provenance of each column — this is why it composes

- **gpu0 is not a projection.** The 2026-08-23 live 3.8 bring-up ran **with the tri
  already resident on gpu0**. `43,579 MiB free after coder eviction`, the util-0.40
  correction, and `5,930 MiB free at idle` all come from that state. A 33,049-token
  prefill drew it to 4,694 MiB and held.
  Source: `docs/model-kb/QWEN38_27B_FP8_CANDIDATE_NOTE.md` §6, §12, §13.
- **gpu1 is the 2026-08-20 trio measurement** (`free 3,994 / 9,946 / 18,305`, gpu0
  44,003 pre-coder) — which had the SMALL RAG on gpu1 at 6,314 MiB, near-identical to
  the 6,038 it holds now.
- **The 3.8 and the RAG never share a card.** gpu0's budget is exactly what §6/§13
  measured; gpu1's is exactly what 2026-08-20 measured; gpu2 carries the tri alone.
  Nothing here is a new combination — that is the whole argument.

## The one variable that changes the answer: WHICH RAG

- **Small root** (`small_service.py --device gpu1`, ~6.0 GiB) — fits gpu1's ~9.9 GiB
  post-tri slack. This is what is live and what the numbers above assume.
- **Full root, 8B embedder** (~15.3 GiB) — does NOT fit gpu1 post-tri. It must go to
  gpu2 (18,305 free), leaving ~2.6 GiB there. That is the 2026-08-20 PM-authorized
  arrangement, so it is known to work, but it is the tight card. Name it before
  flipping the `full-root.conf` drop-in.
- Footprint, not the unit name, identifies which is loaded (`verifier-rag-small`
  serves both). Read `/health` or the cmdline back.

## What co-residency costs the coder seat

It is a **relaunch, not a migration** — off gpu2, up on gpu0 with the bare launcher:

| | dedicated (gpu2, now) | co-resident (gpu0) |
|---|---|---|
| ctx | 262144 | **131072** |
| util | 0.9 | **0.40** |
| KV | ~53 GiB | **5.87 GiB = 162,415 tok (1.24x)** |
| card footprint | 92,394 MiB | 39,155 MiB |

Still one warm 90–100k seat at 2.1–2.5 s/turn (28.7 s cold, prefix caching 89.5%).
But **one seat, not two** — two ~120k seats against a 162k pool thrash to 67–76 s/turn,
~1.7x worse than uncached one at a time. And `--kv-cache-dtype fp8` stops being
optional at that budget: at bf16 the co-resident pool is ~104k tokens, less than one
100k session holds.

## Why the 3.6 must be off — it is arithmetic, not preference

qwen3.6-35b-a3b-q8 measures 40,072 MiB on gpu0 (41,566 MiB live at `-c 262144`) and its
own launcher guard demands ≥40,740 MiB free. Against the tri's leftover 43,579 MiB,
gpu0 hosts **exactly one** of {3.6, 3.8}. That skew is the entire reason `25,37,38` is
the baked tri default.

## What blocks it on the box today (2026-08-25 ~22:00Z)

| GPU | Held by | MiB |
|---|---|---|
| 0 | `qwen3.6-35b-a3b-q8` llama-server `-c 262144` :8081, PID 285437 | 41,566 |
| 1 | RAG `small_service.py --device gpu1` PID 2729 (6,038) **+ ComfyUI `main.py --port 8189` PID 201445 (35,868)** | 41,906 |
| 2 | vLLM `VLLM::EngineCore` PID 15681 — the 3.8 at dedicated max-ctx sizing | 92,394 |

The tri is **DOWN**. The blocker is **gpu1**: ComfyUI holds 35,868 MiB where the tri
needs ~81.6 GiB. Active compute process on an occupied card → CLAUDE.md GPU-active hard
stop, PM's call to clear, not an agent's.

Order after that is the documented one: RAG (self-starts) → tri → 3.8 last.
`ik-llama-server.service` is enabled and restores the tri on reboot by itself; the 3.8
has **no boot unit** and stays one manual command.

## Flag raised, not fixed: a stale warning in the note

`QWEN38_27B_FP8_CANDIDATE_NOTE.md` §6 records the measured OOM fix as
`--max-num-batched-tokens 4096` and says explicitly *do not go back to 8192*. The
committed launcher carries **16384** (`f4c617b4`, the prefix-caching commit). The §13
numbers were taken with the launcher as committed — a ~95k prefill did run at 16384
without dying — so the flag is probably fine and the WARNING TEXT is what is stale.
Not reconciled; nothing edited.

## Sources

- `/data/agentic_trading/scripts/launch_qwen38_27b_fp8.sh` — source of truth for the
  flags, evidence inline per flag
- `/data/agentic_trading/docs/model-kb/QWEN38_27B_FP8_CANDIDATE_NOTE.md` §6 (VRAM +
  the util landmine), §12 (live bring-up), §13 (one-seat production config)
- `/data/agentic_trading/scripts/launch_qwen35_397b_tri.sh` — the split rationale
  (flat/30,35,35/25,37,38 comparison, ~44 GiB gpu0 concentration)
- `2026-08-25_gpu_load_query.md` — how to read card occupancy (driver knows PID+bytes
  only; model identity is a cmdline join; vLLM renames to `VLLM::EngineCore`)

## Note on vantage

This session's sandbox has its own netns: `curl 127.0.0.1:8081` returned "Failed to
connect after 0 ms" for every port including one with a live llama-server on it. Port
probes from here are false negatives. `nvidia-smi` and `/proc/<pid>/cmdline` were the
usable instruments. (The 3.8 launcher's own port guard fails closed on exactly this
condition — it would refuse to launch from here.) See
`2026-08-24_gpu2_slot_inspection.md`.
