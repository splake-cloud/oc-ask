# 2026-09-08 — Gamma backfill substrate: opencode OOM crash (×2) root-caused + bounded-data-access contract made durable

**Thread:** gamma backfill substrate workflow (Investigation 1, Envelope A coverage gate).
**Session under diagnosis:** `ses_f886d9d76ffeWSncO4ka6uq0Je` "SPX signed-gamma reconstruction
blueprint" (19.38M input tokens, 1 compaction `overflow:false`). Subagents it dispatched:
`ses_f84b71762ffeC80ttFOFd60UZq` (first Envelope A, aborted), `ses_f84af3f74ffebUE20rDgaFY5wY`
(re-dispatch, aborted).

## What was asked
"you have been working on a gamma backfill substrate workflow and the opencode session has crashed
twice now. find out why." Then: correct §4.7 + the dispatch envelope, and make a durable
bounded-data-access RAG card (general execution contract, incident as worked example, mechanical
enforcement).

## Root cause (the answer to "why")
**Kernel OOM-killer killed `coverage_gate.py` — it loads the entire ~534 GB / ~813M-row ORATS
per-day pool into one in-memory pandas DataFrame (~248 GB RSS), exceeding the 251 GB host RAM
(3 vLLM servers + RAG resident).** Both crashes are the same script run and killed.

### Detailed crash receipts (kept here, not in the RAG card)

| CLAIM | VERIFY METHOD | PROOF (verbatim) |
|---|---|---|
| Crash 1 @ 09:56:02 = OOM-kill of coverage_gate.py | `journalctl -k` 09-07 | `Out of memory: Killed process 1575237 (python3) total-vm:303810636kB, anon-rss:248491424kB, file-rss:5708kB, shmem-rss:0kB, UID:1000 pgtables:533036kB oom_score_adj:0` |
| Crash 2 @ 10:09:07 = OOM-kill of coverage_gate.py (re-run) | `journalctl -k` 09-07 | `opencode invoked oom-killer … oom-kill:constraint=CONSTRAINT_NONE,…,task_memcg=/user.slice/…/tmux-spawn-4b55814a…scope,task=python3,pid=1592249` / `Out of memory: Killed process 1592249 (python3) total-vm:280456196kB, anon-rss:249510960kB` |
| Both deaths abort the opencode session's tool call | `opencode.log` + session DB | log `2026-09-07T10:09:07.539Z "disposing all instances"` → `10:09:07.577Z cancel session.id=ses_f84af3f74ffebUE20rDgaFY5wY` → `10:09:07.699Z level=ERROR … error=Aborted stack=undefined`; both main sessions' last `task` part = `{"status":"error","interrupted":true}` / `"Tool execution aborted"` |
| The script is the culprit (not context/model) | read `/tmp/opencode/investigation1/coverage_gate.py` | line 92 `orats_all.append(tbl)` for all 183 files → line 106 `orats_df = pd.concat(orats_all, ignore_index=True)` — entire pool in RAM |
| 534 GB pool / ~813M rows in pandas ≈ 248 GB | `du`, `duckdb count` | `du -sh spx_intraday_strikes = 534G`; one date = 4,440,318 rows × 183 ≈ 812M rows; one day = 390 distinct `snapShotEstTime` |

### Mechanism
1. Main session dispatches the Envelope A coverage-gate subagent (`qwen-coder`), which runs
   `python3 /tmp/opencode/investigation1/coverage_gate.py`.
2. Step 3 (`coverage_gate.py:82-106`) reads all 183 per-date ORATS files (534 GB, ~812M rows) via
   `fetchdf()` into a list, then `pd.concat` → one DataFrame ≈ 248 GB in pandas (uncompressed,
   object-dtype date columns).
3. Host RAM = 251 GB (with 3 vLLM + RAG resident) → global OOM. Kernel kills the 248 GB `python3`.
4. bash child dies → opencode aborts the tool call (`"Tool execution aborted"`) and tears down the
   session (`"disposing all instances"` / `error=Aborted`). User re-opens a session; 2nd run hits
   the same wall 13 min later.

### The defect
The dispatch envelope's **constraint #2 explicitly required** *"Process day-by-day (stream) to bound
memory"* — but the script only streams the **join** (step 5); the **ingestion** (step 3) loads every
file at once. The day-by-day loop operates on the already-materialized `orats_df`, so memory was
never bounded. Memory-architecture bug in the script, not a model/context problem (the main session
had already compacted with `overflow:false`).

## Why the data-access profile didn't stop it (the transfer failure)
The blueprint §4.7 **did surface** the hazard (573 GB pool, forbidden glob, stream-don't-materialize)
and even prescribed per-day streaming. It failed to bind the build because:
1. **Wrong workload scoped.** The mitigation was sized for the **≤5-minute decision slice** (L249,
   L270: "snapShotEstTime=1130 → 12,898 rows; +expirDate=tradeDate → 322 rows"; rule #4's "row-group
   read ratio ≪ 0.5"). The coverage gate is a **different** access pattern — the full 390-snapshot
   chain — for which "never materialize a full day file" is literally unsatisfiable. The profile
   flagged "all-expiry is a bigger but still bounded read" (L276-281) but **never bounded its
   memory**. The builder was not handed a bound it could violate; it was handed one that didn't map
   to its task.
2. **Prose, not mechanically-checkable.** "Stream, do not materialize" is an intent; nothing in the
   build's VERIFICATION asserted peak memory. The profile's "resource behavior" evidence (P5/P6) was
   a 322-row slice, <0.1 s — it verified the access pattern *it specified*, not the one the build
   *used*.
3. **Lost in translation into the envelope.** The profile carries 7 binding rules + row-group detail;
   the envelope carried **one line** (constraint #2 "stream to bound memory"). The builder followed
   that line's **letter** (its step-5 join IS day-by-day) while violating the profile's **intent**
   (it pre-loaded ingestion in step 3).
4. **No enforcement at scale.** The full 183-day run had no maxrss gate; the OOM was found at runtime
   by the kernel, not at verification.

**Accountability seam = the dispatching seat**, not the builder: the builder reasonably implemented a
one-line constraint that was ambiguous for its workload; the profile's value is realized or voided by
whether the orchestrator made it load-bearing in the envelope + verification. Here it was made
advisory, so followed in form, ignored in substance.

### Corrections the PM made (banked)
- **78×, not 390×**: full 390-snapshot chain vs a ≤5-minute slice = 78×; 390× is only vs a
  one-minute slice.
- **"Never materialize a full day file" is inapplicable** to the coverage workload (it intentionally
  examines the full day). Corrected distinction: **may scan all required rows of a day, but must not
  materialize those raw rows in pandas or retain a day's rows after that day is joined and reduced.**

## What was done (deliverables)
1. **Blueprint §4.7 corrected** (`/tmp/gamma_backfill_working_hypothesis_blueprint.md`): added
   decision-slice-vs-full-chain note (78×/390×), the scan-vs-materialize binding distinction, the
   max-live-set bound; rewrote binding rule #4 ("scan the day, never retain it"); added binding rule
   #8 (mechanical memory enforcement: static audit + 3-5 day smoke run with RSS plateau assertion +
   peak-RSS ceiling + incremental-output reconcile; do-not-rely-on-tracemalloc-alone); added §17 **P8
   incident** record (summary + pointer to this card for receipts).
2. **Corrected dispatch envelope** as a durable file:
   `analysis/sml_fly_verify/gamma_topology/INVESTIGATION1_ENVELOPE_A.md` — corrected constraint #2
   (scan-vs-retain, max-live-set, no cross-date raw-row container, process-per-day-emit-per-day) +
   new VERIFICATION clauses **M1** (static materialization audit), **M2** (3-5 day smoke run, RSS
   after every day + `ru_maxrss` peak + plateau assertion + ceiling), **M3** (reopen + reconcile
   incremental outputs), **M4** (full run + report peak RSS), **M5** (independent re-derivation).
3. **Durable RAG card** in the `data_contracts` well:
   `bounded_data_access_full_chain#__contract__` (`scripts/rag_verifier/build_contracts.py`). A
   **general** bounded historical-data execution contract (trigger terms: full history, large parquet
   pool, multi-day ingestion, coverage gate, reconciliation, read_parquet glob, fetchdf, pandas
   concat, batch processing, memory pressure, OOM, backfill, cross-date accumulation) with the
   incident as a worked failure example + the mechanical-enforcement rules. **Shipped:** scan-stage
   (88 cards, +1) → live in **both** roots (`missing=0 stale=0`, text matches) → **retrieves #1**
   (score 7.56) for the trigger query via live `:8765`.
   - **Note:** a thinner pre-existing card `big_pool_streaming_access#__contract__` (v2026-06-17,
     "stream or iterate, never accumulate raw days") + a `failure_priors:unbounded_read_or_full_scan`
     prior (93 incidents) already cover part of this ground. The new card supersedes/complements with
     the full mechanical-enforcement contract + worked failure; the older card left intact (not
     wrong, just thinner). PM may want to fold/retire `big_pool_streaming_access`.
4. **This session-memory card** (detailed receipts).

## Open / next
- **The corrected Envelope A has NOT been re-dispatched.** The builder still needs to implement the
  corrected constraint #2 (per-day scan, discard-after-reduce, M1-M5 verification) and pass the smoke
  run before the full 183-day run. That is the actual resume point for the gamma backfill substrate.
- RAG card seeding: `data_contracts` is live in both roots (seeded this session, CPU). No other
  well touched. No GPU floor issue this time (CPU seed, no `--recreate` foreground trap).
- `coverage_gate.py` itself is NOT fixed (read-only diagnosis + contract fixes only); the fix is
  embodied in the corrected envelope for the next dispatch.
