# 2026-09-11 — paper-corpus retrieval service (:8090): orphaned → stood up → zero-model architecture

## What happened
User asked whether the old "reference papers RAG" (`papers_corpus`) was integrated into the live
RAG and whether its separate service was still up. Findings: it was **evaluated for merge and
deliberately kept separate** (docs/RAG.md §11, 2026-07-27 — starvation: infra ~575 candidates vs
claims ~32, backfilled claims scored 2.688 vs infra 6.812). The standalone retrieval service
(`scripts/paper_corpus/serve_retrieval.py`, port 8090) was **down with no retirement record** —
last log Jun 7 2026, no systemd unit, no memory card, no doc. Stood it back up, then (PM: "why
persist another rag model when I already have a rag stack up that is always on") re-architected
it to persist **zero models**.

## Final state (live)
- `:8765` (always-on RAG, `/data/parquet/verifier_kb` FULL root, 8B embed+rerank on gpu2) gained
  an additive `POST /rerank` endpoint: `{"query","texts"[≤256]}` → `{"scores"[aligned],"n",
  "rerank_model","rerank_device"}` — resident cross-encoder, `VERIFIER_KB_RERANK_BATCH` (default
  8) OOM guard (PM 2026-07-04: all-at-once 70-80-candidate rerank on 8B = ~94 GB OOM), raw signed
  logits, model id echoed for fail-closed client checks.
- `:8090` = thin stateless client: holds the LanceDB claims table
  (`/data/parquet/papers_corpus/indexes`, 3,413 claims), query vector via `POST :8765/embed`
  (`prompt_name="query"`, client L2-normalizes — `/embed` returns RAW vectors), dense+BM25 on CPU,
  rerank via `POST :8765/rerank`. No torch import, no CUDA context (verified: 0 libtorch/libcuda
  mappings in the process). `/load`/`/unload` no-ops; 34 GB gate retired in remote mode.
  `--local-models` flag preserves the old local-copy behaviour.
- Commits: `754f04c3` (3 code files) + README commit. `launch_retrieval_service.sh` NOT updated
  (still old venv + old default index) — launch with the README command directly.

## Traps banked
1. **`DEFAULT_LANCE` is stale** — points at `.ai/reference/papers_index/indexes` (Jun 4, 417
   claims). Live corpus is `/data/parquet/papers_corpus/indexes` (Jun 5, 3,413 claims). Always
   pass `--lance-dir`.
2. **venv split**: `/data/agentic_trading/.venv` has lancedb+numpy+rank_bm25 (run the service
   with it in remote mode); `.venv-vllm` has torch/sentence-transformers but **no lancedb**.
3. **`:8765` runs OUTSIDE systemd** (PPid 1; unit `verifier-rag-small.service` inactive/disabled).
   Its config lives only in its process env: `VERIFIER_KB_ROOT=/data/parquet/verifier_kb`,
   `VERIFIER_KB_EMBED_MODEL=/data/models/qwen3-embedding-8b`,
   `VERIFIER_KB_RERANK_MODEL=/data/models/qwen3-reranker-8b`, `VERIFIER_KB_DIM=4096`,
   `VERIFIER_KB_RERANK_BATCH=8`, `PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`,
   cmdline `--host 127.0.0.1 --port 8765 --device gpu2 --warm`, cwd `/data/agentic_trading`.
   Restart = capture `/proc/<pid>/environ` + cmdline FIRST, kill, relaunch with nohup.
4. **`/embed` returns RAW (unnormalized) vectors** — kb_store applies `_l2()` itself; normalizing
   in the endpoint would double-normalize one path. Prompt asymmetry (docs none / queries
   `"query"`) is load-bearing.
5. The "embed drift after restart" scare was a **malformed baseline probe** (broken one-liner
   printed raw values), not a regression — the retrieval A/B (same query, old vs new process)
   returned byte-identical top-4 with identical scores.

## Open / done (2026-09-11 cont.)
- `launch_retrieval_service.sh` repoint — **DONE (commit 620e939e)**: .venv python +
  `--lance-dir /data/parquet/papers_corpus/indexes` actually passed + remote-mode messaging.
  Smoke-tested through the launcher on :8091 (status + search OK, test instance killed).
- `:8765` supervisor — **DONE (2026-09-11)**: PM ran the staged root sequence; unit is now
  `enabled + active` under systemd with the captured config (cmdline proves `--device gpu2`;
  /health proves full root + 8B pair; the stale gpu1 drop-in is gone). Verified: /health,
  /search (doctrine_clauses returns cards), :8090 /search end-to-end. Both RAG services now
  survive reboot/crash (Restart=always, StartLimit* actually in [Unit]).
- `merged_service.py` / `project_paper_claims.py` remain dormant per §11 (corpus merge still
  rejected; this work is model sharing, not corpus merge).
