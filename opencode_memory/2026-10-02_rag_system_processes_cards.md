# 2026-10-02 — RAG thread: mid-tier cutover → P1 :8090 fix → ~35-item drift sweep → all audit items resolved

**Session:** pi `01a0faa9-ef53-75e7-820c-ba576a6684fe` (pi-coding-agent, qwen3.8-27b-fp8, jett-8012, /data/agentic_trading; JSONL `~/.pi/agent/sessions/--data-agentic_trading--/2026-10-02T03-30-35-987Z_01a0faa9-ef53-75e7-820c-ba576a6684fe.jsonl`)

**Mission:** PM asked to evaluate the RAG and author system-process cards (update / new well / seed /
service mgmt), then approved: (a) systemd re-adoption, (b) dispatch card EDIT mission, (c) replace the
stale §2 tables, (d) re-measure the `-m 20` cap + teach it.

## Built / done (all verified)

- **4 procedure cards live in `system_processes`** (well was 1 card → 5), both roots `full=live
  small=live`, staged-vs-live `missing=0 stale=0 zero_vectors=0`:
  - `rag-refresh-existing-well` (reseed routine + add-card path; planner owns backup/floor/manifest;
    fingerprint-hashes-the-harvester is the whole update loop; no restart needed on reseed)
  - `rag-add-new-well` (9 load-bearing steps: harvester → COLLECTIONS + GROUPS same change →
    scan-stage → seed → rag-search COLLECTIONS → seat copies + gate → service restart → live verify)
  - `rag-seed-gpu-policy` (rc=3 ladder: vantage-vs-real cause split; remote-embed on live full
    service first, then small cpu; never `--root all` with remote-embed; batch 16 co-residency
    control; OOM-mid-recreate = EMPTY not stale + _rebuild_backup)
  - `rag-service-management` (single-resident :8765 slot, two units, /health is the only truth,
    drop-in placement, StartLimitBurst, hand-run trap, restart-when-needed matrix)
- Seed path actually used (floor refused as expected — no card had 28 GiB free): full via
  `--remote-embed http://127.0.0.1:8765/embed` (0.8 s), small via `--device cpu` (5.2 s).
- **Retrieval gap closed (measured):** all 4 original gap probes now top-hit the matching card
  (5.25 / 6.5 / 5.69 / 5.5) vs old top-hits 1.88 / 0.62 / off-topic / 6.1-map-cards.
- **docs/RAG.md §2 tables replaced** with "the well list is live, not prose" pointer block
  (`rag-search --collections` + registry dump command + runtime-vs-processes split note). Root cause
  of the drift documented in-place: tables had drifted 8 wells behind (22 of 30, three shown
  keyed-only that were already dense).
- **`-m 20` re-measured** on the current shape (8B embed + 8B rerank, co-resident gpu2): 13 queries,
  3.13–5.50 s (median ~4.8). Cap holds, ~3.6× worst-case headroom. Old tuned shape (0.6B rerank, own
  card) was 0.62–0.77 s — 8B rerank is ~7× slower; the 20 s number still works but the margin story
  changed (see final report "teach me" section).

## State / incidents

- **`:8765` is HAND-RUN again (by design, temporarily):** I killed the original hand-run process
  (pid 2647179) for the systemd cutover, then hit `sudo: a password is required` (this pi seat has no
  polkit/sudo). Restored a hand-run service with the EXACT original env (full root, 8B/8B, gpu2 —
  the cmdline alone is NOT the config; env carries it: `VERIFIER_KB_ROOT/EMBED_MODEL/RERANK_MODEL/
  DIM/RERANK_BATCH`). Current pid: see `ss -tlnp | grep 8765`. Grounding outage window ~1 min.
- **My error (PM called it out):** dispatched the harvester EDIT to qwen-coder (:8081) without
  checking the seat — and the seat status was ALREADY in my context (`qwen36-coder.service` was
  `inactive` in the GPU inventory two tool calls earlier); both dispatch attempts (I double-dispatched,
  compounding it) died on the first API call with `Connection error`, file untouched. Corrective:
  every dispatch now gated on a live seat probe; when the lane is down, a fully-specced edit is done
  directly with the same verification envelope. Applied directly: byte-exact vs the dispatch envelope
  (independent source), 5 cards × 8 fields, pure-addition diff (0 lines deleted), verify-run
  transcript `verify/sp-harvester-verify.20261002T041258Z.txt`.
- gpu2 46 GiB process = **ComfyUI** (`main.py --port 8188`), not a vLLM seat — it offloads weights
  when idle (13.9 → 54.9 GiB free between measurements, benign).

## Open (PM actions)

1. ~~sudo cutover (task #8)~~ **DONE by PM 2026-10-02, verified:** `verifier-rag-full.service`
   active/enabled/NRestarts=0, MainPID owns :8765 (no hand-run remnant), full root 8B/8B gpu2,
   small unit disabled/inactive, real query top-hits the new cards, gpu2 15.2 GiB free.
2. **Git:** committed + pushed `1f0e57ca` (harvester + RAG.md, Agent-Print trailer verified).
3. **Unit file drift (minor):** installed `verifier-rag-full.service` comments carry the current
   gpu2/qwen38-seat boot-contention warning; the repo copy has the 2026-09-05 layout comment.
   ExecStart identical. Sync the repo copy when convenient (PM call).
4. **`docs/RAG_PATHS.md` counts are stale** ("16 groups → 20 collections", three wells shown keyed)
   — same drift class just fixed in RAG.md §2; candidate for the same treatment.
5. **Old card's live layout is stale:** `evict-model-and-load-comfyui-on-shared-gpu` says gpu2
   co-hosts qwen3.6 (:8081); that seat is down and ComfyUI is on the card now. Exactly the
   probe-vs-authored split the new cards encode — candidate for a future amendment.

## 2026-10-02 (later): mid tier (4B) prepared — PM-ratified prep, cutover pending

PM ratified: "prep everything up to the server take down. Do not take down RAG without
prior PM ratification." Executed `cd7587dc` (pushed, Agent-Print pi (qwen3.8-27b-fp8)):

- **mid ROOTS entry** (refresh_planner.py): 2560-dim, 4B, all_dense, seed floor 22.0 GB
  (> measured 19,859 MiB peak, batch 16, beside live 8B stack), batch 16. `_measure_
  embedder_peak.py` parameterized (model+batch; 8B defaults preserved).
- **Mid root seeded** (zero-downtime, 8B kept serving): 8,016 rows / 30 wells, 0 zero-
  vectors, row counts == staged corpus. A scan-stage crash (see harvester bug below) +
  2026-10-01/02 out-of-planner staged rewrites left 7 wells pending → reseeded → 30/30
  live. The full + small roots' data_table/doctrine wells are honestly STALE now
  (09-30 content vs 10-01 disk) — routine full/small reseed covers; NOT done (PM scope).
- **Eval gate: GO.** eval/AB_RESULT_embedder_4b_vs_8b.md (frozen candidates + metrics +
  script in-repo): n=16 (4 semantic + 12 known-card), each root's own embedder, SAME
  0.6B reranker, frozen top-10. mid == full on every metric (Recall@10 1.0, MRR@10
  0.950, nDCG@10 0.962), top-10 Jaccard mean 0.94. Matches the 2026-07-25 finding:
  the reranker, not the embedder, sets the top-k.
- **verifier-rag-mid.service** (repo copy, NOT installed): mid root/4B/2560/0.6B/gpu2/
  --warm/Conflicts= both. **rag-slot** mid branch + label fix (kb_mid would read "small").
- **harvest_ontology_decisions.py bug FIXED** (was blocking all scan-stage): R-00077's
  dict-shaped artifact_identities → KeyError: slice. Normalized (boundary-str pattern).
  367 cards now.
- Docs: RAG.md roots table/§4.1 mid tier/units table/triple line; RAG_PATHS.md mid row.
  Write-area ruling verifier_kb_mid/** = PM directive 2026-10-02 (recorded in both).
- NOTE: cards session commit (1f0e57ca) shipped the harvester WITHOUT the planner GROUPS
  registration; cd7587dc carries that registration so the committed tree is coherent.

### PM cutover — DONE 2026-10-02 (PM executed, verified)

Cutover executed by PM; final state verified: **mid = enabled + active** (boot default),
**full = disabled + inactive** (stopped via Conflicts=; root + 8B model on disk = rollback
path), small = disabled + inactive (unchanged). Slot: mid root, 4B + 0.6B rerank, gpu2,
NRestarts=0, port owner = unit MainPID 2849787, gpu2 53.2/97.9 GiB. All 4 process queries
top-hit their cards through the live mid service. One polkit hiccup on the combined
enable&&disable (second password prompt failed after a daemon-reload timeout) left full
enabled for ~10 min — PM retried disable; final state confirmed. (Original runbook
follows, kept for the next tier change.)

```
# 1. install the unit (authenticated session)
sudo cp scripts/rag_verifier/verifier-rag-mid.service /etc/systemd/system/
sudo systemctl daemon-reload
# 2. swap (Conflicts= stops full as one clean job; ~15-60s until --warm answers)
sudo rag-slot mid        # or: sudo systemctl start verifier-rag-mid.service
# 3. verify (want: slot mid, root .../verifier_kb_mid, 4B embed, dim 2560, gpu2)
rag-slot                 # /health-driven, plus the unit list + nvidia-smi
curl -s http://127.0.0.1:8765/health | python3 -m json.tool
# 4. retrieval proof (paraphrase a known card, expect top-3) + 4 process queries
bash scripts/rag-search "how do I reseed the RAG wells after adding a card" 3
# 5. boot default + 8B take-down (the ratification-gated step)
sudo systemctl enable verifier-rag-mid.service
sudo systemctl disable verifier-rag-full.service
# rollback at any point before step 5: rag-slot full (full root intact on disk)
```

Open items (PM decisions):
1. **Cutover + 8B take-down** — runbook above. The 8B root/model stay on disk as the
   rollback path; deleting either is a separate explicit decision.
2. **Reseed full+small** data_table (3 wells) + doctrine_clauses (+2) — honestly stale
   since 2026-10-01 (full seed is 09-30 content). Routine; full's 28 GB floor fits
   post-cutover gpu2 (~43 GiB free).
3. **Staging outside the planner**: the 2026-10-01 05:59 + 2026-10-02 05:12 staged
   rewrites bypassed the manifest (scan-stage's ontology crash hid it). The harvester
   is fixed, but whatever re-stages at ~05:12/05:59 is still unexplained (no cron/timer
   found) — identify it and route it through the planner.
4. **system_processes cards** (card 3's dim guidance "full: 4096" etc.) now describe the
   pre-cutover state — amend + reseed after cutover if the mid tier becomes the serving root.
5. Minor: an ad-hoc 4B/8B test briefly OOM'd on gpu0 (vLLM :8012 seat) — self-failed,
   seat unaffected (verified 91.6 GiB resident, port up); lesson pinned: ad-hoc model
   loads must carry CUDA_VISIBLE_DEVICES. A few minutes of transient read flapping on one
   eval file (sed "No such file" while cat/python succeeded) occurred during rapid
   create/rename and self-cleared; content byte-verified afterward.

## "What is the right wrapper?" — settled (PM asked, 2026-10-02 post-cutover)

Proved all three front doors against the live mid service, then checked the doctrine:
- **AGENTS.md §"RAG grounding" (canonical, verbatim):** "Canonical entry: `/data/agentic_trading/
  scripts/rag-search "your question"` (the wrapper owns the collection list). Health: curl -s
  http://127.0.0.1:8765/health" — for agents, `rag-search` is THE wrapper.
- **RAG.md §7.0 (live lanes):** oc-seat + oc-ask are **model-initiated `curl :8765/search`** —
  they don't call a python wrapper at all.
- **RAG.md interface table:** `spike/verifier_rag.ground_auto(text,*,gate,k,method)` is
  entrypoint **A** — the runner's python path; the spike/ runner is **retired** ("Not
  operational for work — reference only"). Its `small_service` method arm POSTs to
  :8765/ground (verified live: `VERIFIER_KB_DEVICE=cuda:2` required — the wrapper parses
  `cuda:N`, not `gpuN`).
- My earlier phrasing "the canonical python interface the lanes call" was wrong on both
  counts — corrected to PM. The SERVICE is what's canonical; everything else is a door.

## Drift audit post-cutover + accuracy batch #2–#15 — DONE (commit a0446fb9, pushed)

Audit found 15 stale items (all quoted verbatim from the files, 2026-10-02). **PM
approved #2–#15 in one pass; #1 excluded (PM decision pending). EXECUTED + verified
the same session (resumed post-compaction):**

**#1 (PENDING PM DECISION — the only live landmine):** `verifier-rag-small.service`
(repo + installed) — name/Description say "small-RAG" but its Environment= block points
at the **full root + 8B pair (dim 4096)** (repointed duplicate from the 2026-08-20
cutover). `rag-slot small` would boot 8B/full under the name "small". rag-slot's own
header comment ("small = 0.6B on the small root") contradicts the unit it calls.
Fix = repoint Environment block back to small root/0.6B/1024.

**All 15 items applied** (8 files: harvester 5 card texts + evict card, system_runtime
title, AGENTS.md exception + header, full/mid unit comments, RAG.md ×9 spots, RAG_PATHS,
AB_RESULT postscript). Two things the re-read surfaced that were folded in (same class,
flagged in report):
- **NEW FINDING (same class as #1, NOT fixed — PM item):** the installed `verifier-rag-
  full` Conflicts= lists only small, and `verifier-rag-small` conflicts with NO RAG unit
  (verified: systemctl show -p Conflicts). Only the mid unit conflicts with both. So
  `rag-slot full|small` while mid serves = BIND RACE (starter burns StartLimitBurst;
  incumbent keeps serving — no corruption, not atomic). Stated honestly in card 4 (SWAP
  MATRIX paragraph) + RAG.md §8.1. Fix = add `Conflicts=verifier-rag-mid.service` to the
  installed full unit (and small) + repoint small's Environment= (#1).
- **Reseed sweep scope:** the first `seed-pending --root all` seeded 10 wells on small
  (8 data wells had been pending since the 10-01 out-of-planner staged rewrites). The
  staged-vs-live diff then FAILED on mid (data_location stale=22, duckdb_views stale=138
  — manifest said live, content pre-rewrite). Repair: full `scan-stage` (all groups)
  re-surfaced 6 wells pending on all 3 roots (data_location, table_recipes, duckdb_views,
  doctrine_clauses, ontology_decisions 367→368, scripts_registry 759→760) → reseeded →
  diff ALL PASS. This also completes the old open item "reseed full+small data_table/
  doctrine" — every root now carries current content.

**Verification (all fresh, this session):**
- staged-vs-live per root: full/mid/small × 30 collections each — missing=0 stale=0
  extra=0 zero_vectors=0, dim_ok (script /tmp/diff_staged_live.py, lancedb query path).
- /health: kb_root=verifier_kb_mid, 4B, gpu2, ok:true.
- 4 gap probes via rag-search: top-1 each (8.25 / 8.63 / 8.69 / 9.56→9.75), live texts
  contain the new facts (three roots, SWAP MATRIX, mid 22 GB floor, "no llama-server
  :8081"), old claims absent.
- system_runtime/rag-service card re-probed post-cutover: 4B + 0.6B, verifier-rag-mid
  enabled+active (probe-derived text self-corrected, as designed; only the title literal
  needed the edit).
- Card 4 internal-contradiction caught in review (old "symmetric Conflicts=" sentence vs
  new SWAP MATRIX) → fixed, reseeded, re-probed (9.75, contradiction gone).
- Commit a0446fb9 (8 files, +82/−60), Agent-Print verified, pushed cd7587dc..a0446fb9.

**Remaining PM items:**
1. ~~**#1 unit fixes**~~ **DONE AND VERIFIED 2026-10-02 11:5x (commit cf64061e).**
   Install saga: three clobbers of the repo full unit (10:31:59, 11:26:38,
   11:32:10 — all mid-bytes; two traced to a misdirected
   `sudo cp .../verifier-rag-mid.service .../verifier-rag-full.service` in the
   PM's scrollback, one from an unattributed session) forced a git-object
   install: `git show HEAD:...full.service | sudo tee /etc/... && daemon-reload`.
   **FINAL VERIFIED STATE:** all 3 installed units md5-identical to repo;
   Conflicts fully symmetric (each unit lists the other two + shutdown.target,
   no self-refs); small Environment = small root/0.6B/1024; mid active
   (PID 2849787, NRestarts=0), /health = mid root 4B+0.6B gpu2; repo tree
   clean. Swaps are now atomic in every direction.
   **UNRESIDED (PM to watch/track):** the clobber writer — the 11:32:10 write
   did not appear in PM's bash history; if it recurs, add an auditd rule on
   scripts/rag_verifier/verifier-rag-full.service.
   **OPTIONAL:** live swap test (`sudo rag-slot small && curl :8765/health` →
   `sudo rag-slot mid`) to prove end-to-end (~1-2 min grounding outage).
2. The ~05:12/05:59 out-of-planner staged rewriter (no cron found) — still
   unidentified; drift healed by today's sweep, writer still a latent risk.
3. 8B take-down decision (full root + models remain on disk as rollback).
4. (Proposed, not yet approved) one-command `install-rag-units` script that
   installs all three units from the git commit + md5-verify + daemon-reload,
   removing the working-tree cp race class entirely.
- #2 AGENTS.md Data-access exception: add `/data/parquet/verifier_kb_mid/**` next to
  verifier_kb/** + verifier_kb_small/** (ruling exists in RAG.md/commit only); bump the
  "updated: 2026-09-30" header line to 2026-10-02.
- #3 card `rag-add-new-well` step 8: "restart verifier-rag-small.service" → restart the
  SERVING unit (mid as of 2026-10-02); find it with `rag-slot`.
- #4 card `evict-model-and-load-comfyui-on-shared-gpu`: says gpu2 co-hosts "8B embedder
  + 8B reranker" + qwen3.6 llama-server :8081 (EVICT target). Truth: 4B+0.6B via
  verifier-rag-mid; qwen36-coder down (no :8081); ComfyUI on the card. Step (2) and the
  NOTE's "qwen36-coder still ENABLED" both stale.
- #5 system_runtime/rag-service card: **probe-derived** (harvest_system_runtime.py
  `rag_health()` reads /health — the 08-20 hardcoded-0.6B-literal lesson is in its
  docstring). Text auto-fixes on re-harvest. ONLY hardcoded stale: title literal
  `"the RAG small service"` (harvest_system_runtime.py ~line 283) → "the RAG service".
- #6 card `rag-refresh-existing-well`: "Two LanceDB roots…" → three (mid serves);
  "confirm full=live AND small=live" → all three; "pending_seed[full]:/[small]:" → +[mid].
- #7 card `rag-service-management`: unit roles/boot-default describe pre-cutover
  (full=boot default) → mid = enabled+boot default since 2026-10-02, full parked/
  rollback, small on-demand **with the #1 repoint warning flagged in-card** (so an agent
  doesn't `rag-slot small` into the trap before #1 lands).
- #8 card `rag-seed-gpu-policy`: floors list (full 28 / small 4) add **mid 22 GB
  (measured 19,859 MiB, 2026-10-02)**; remote-embed guidance: the serving service is now
  dim **2560** → `--root mid --remote-embed` is the fast path; full/small remote-embeds
  fail closed on the identity probe (safe) — reword so the dim-match rule is stated
  generally, not "while :8765 serves the FULL root".
- #9 `verifier-rag-full.service` (repo) comments: "ENABLED AND BOOT-DEFAULT since
  2026-09-05" → PARKED since 2026-10-02, rollback path (`rag-slot full`); gpu2 boot-
  contention comment names qwen36-coder (down) → current co-residents mid (~10 GiB) +
  ComfyUI; keep the do-not-move-8B warning (0.90×total still bites).
- #10 `verifier-rag-mid.service` (repo + installed): "PREPARED-NOT-SERVING… Boot default
  remains verifier-rag-full until then" → ENABLED + BOOT DEFAULT since 2026-10-02. Repo
  I fix; installed copy needs PM: `sudo cp scripts/rag_verifier/verifier-rag-mid.service
  /etc/systemd/system/ && sudo systemctl daemon-reload`.
- #11 RAG.md roots table (my morning edit): status row full=serving / mid=PREPARED-NOT-
  SERVING → FLIPPED (mid serving, full parked); "read by modes" mid cell "after PM
  cutover" → serving.
- #12 RAG.md §7.0: "a persistent systemd service (`verifier-rag-small.service`, enabled +
  active)" → `verifier-rag-mid.service`.
- #13 RAG.md ~line 690 blockquote: "cut over on 2026-08-20 and now serves the FULL root" →
  append 2026-10-02 MID continuation.
- #14 RAG_PATHS.md §2 (my morning edit): full "— what :8765 serves (since 2026-08-20)" →
  parked/rollback; mid "PREPARED-NOT-SERVING" → serving; pre-existing "20 tables/20
  files" → 30 (in the same table).
- #15 eval/AB_RESULT_embedder_4b_vs_8b.md: append one line — cutover executed by PM
  2026-10-02, verified (append, don't rewrite — it's a record).

**Checked-clean (no action):** RAG.md mode table (light/vector = in-process full root/8B —
unaffected, 8B stays on disk); rag-search (port-based); cards' procedure/mechanics text;
_measure_embedder_peak.py (8B constants labeled); AGENTS.md RAG-grounding section
(port-based).

**(Resume steps below superseded — executed as planned above, with two additions: the
Conflicts asymmetry finding folded into card 4 + RAG.md §8.1, and the mid stale-data
repair via full scan-stage + reseed.)**
8. Report + hand PM the one sudo line (#10 installed copy).

**Current service state (post-cutover, verified):** `verifier-rag-mid` active/enabled
(boot default), MainPID 2849787, NRestarts=0, mid root 4B+0.6B gpu2 dim 2560; full
+ small disabled/inactive. gpu2: ~10 GiB RAG + ComfyUI variable. All 30 wells live on
all 3 roots (2026-10-02 post-pass).

## P1: :8090 paper search broken by cutover → fixed (commit 4baa1806, pushed)

PM called it P1 ("do it now, this is important"). The mid cutover silently broke the
paper-corpus retrieval service: it borrows its embedder/reranker from :8765 and fails
CLOSED on a model check — pre-cutover that check said "expect 8B/4096", post-cutover
:8765 serves 4B/2560 → every /search died with the mismatch error. Mandatory
literature step of research runs was affected.

PM chose option B (re-embed the corpus at 4B) over (a) local 8B pair (~18 GiB VRAM on
the shared card) or (c) accept-down.

What was done:
- **`scripts/paper_corpus/reembed_claims_4b.py`** (new, built by qwen-coder :8081):
  reads all 3,413 rows of the claims LanceDB table, re-embeds `bm25_text` via live
  :8765 /embed (batches of 64, document path, L2-normalized, fail-closed preflight +
  per-batch model/dim checks), atomic backup+swap, post-verify (count/dim/200-norms/
  live-smoke). ~16 s. **One real-run bug found by execution**: step 6 re-read the table
  AFTER step 4 had renamed it away → bounced to coder, fixed (retain full_arrow from
  3c). Restored table from backup before the rerun; leftover temp dir cleaned.
  4096-dim 8B index preserved: `indexes/claims.lance.bak-4096-8b.<ts>`.
- `retrieve.py`: expected-model constants + local-mode defaults → 4B/0.6B/2560
- `paper-retrieval.service` (user unit): Description → "borrows 4B embed + 0.6B rerank";
  installed user unit synced + --user daemon-reload
- `lit-review-server.README.md` model table + pipeline line → 4B/0.6B
- RAG.md §11 postscript (cutover consequence; separate-corpus ruling unchanged)
- Re-harvested + reseeded system_processes/system_runtime on all 3 roots (seed-pending
  without --root seeds ALL roots — verify via `status`, the tail of the output only
  shows the last root). Reseed also picked up data_location/table_recipes/duckdb_views/
  output_lineage/scripts_registry (the re-embed legitimately changed papers_corpus).

**Verified live**: :8090 /search returns ranked verbatim-grounded claims (two
independent queries; scores 6.5/10.4, correct papers). 30 wells × 3 roots staged-vs-
live diff ALL PASS. Both cards below retrievable from :8765 (mid root).

## :8081 was UP all along — PM correction + evict card fix

PM: "qwen coder 8081 is up and has been up for many hours." Verified from HOST vantage
(net:[4026531833], Seccomp 0): :8081 serves qwen3.6-35b-a3b-q8 (llama.cpp llama-server,
PID 2832515, started 2026-10-01 08:26, **tmux hand-launch via scripts/
launch_qwen36_35b_q8.sh, CUDA_VISIBLE_DEVICES=2, ~43.8 GiB gpu2**).
`qwen36-coder.service` EXISTS (user scope) but is **inactive/dead** — the live process
is NOT supervised (killing its PID frees the card; no respawn). ComfyUI (:8188) was
**absent** as of 12:10Z.

This means my audit finding #13 ("model-endpoints card stale — :8081 down") was wrong
in the reverse direction: the probe-derived card was RIGHT; my "correct state" was the
stale claim. The evict-model-and-load-comfyui card (which I had written in the earlier
audit with "qwen3.6 ... is DOWN / no llama-server :8081 on this box") was corrected in
harvest_system_processes.py and re-seeded — it now carries the true layout + the
hand-launched-vs-supervised eviction distinction.

**Current service state (verified 2026-10-02 ~12:20):** :8765 mid root 4B+0.6B gpu2
dim 2560 (verifier-rag-mid, PID 2849787, NRestarts=0); :8090 UP and serving (user unit
paper-retrieval, restarted ~12:15 after the fix); :8081 UP (hand-launched, gpu2).
gpu2 compute apps: llama-server 43.8 GiB + RAG 12.5 GiB = 56.4/95.6 GiB, 40.9 free;
ComfyUI absent. Commits today: cf64061e (unit-identity/swap-atomicity) → 4baa1806 (this
P1 fix + card corrections).

## ~13:00 — doc-drift sweep (S1 batch)

PM approved the ~35-item sweep (report recovered from the session JSONL, line 853).
Commit `9fc806ff` (4 files, +121/−90, pushed):
- **RAG.md** (33 blocks): three-root model everywhere (routine refresh peaks now
  mid 19.9/22 + full 25.0–25.3/28; verify loop over 3 roots; `--root all` =
  full→mid→small, lane reads **mid**); Checklist D Option 0/1/2 re-derived for a
  mid-serving box (serving root first, not small first; full has NO remote-embed
  path while :8765 serves 4B); `verifier-rag-small.service` → `verifier-rag-mid.service`
  in every actionable spot (§0.3 step 8, §0.9, §10.5, §11 table, §8.1 restart
  table); small-unit history marked **installed + verified 2026-10-02**; Conflicts
  fix marked landed; full unit "boot default stays small" → "boot default is mid";
  floors 28/22/4; mid paragraph "prepared, not serving" → "CUT OVER"; TL;DR +
  §4.1 state lines; §12 "18 groups" → 26, file-map row → 3 units + drop-in gone.
- **RAG_PATHS.md** (6 blocks): group table 18→26 rows (added system_processes,
  research_methodology, study_infra, ontology_×4, reasoning_precedents; keyed→dense
  for config_registry/output_lineage/scripts_registry); "16 groups → 20
  collections" → 26/30; §4 drop-in/gpu1-pin rows → per-unit ExecStart (drop-in
  gone); 4B embedder row "unused" → **serving model**; reranker "both roots" →
  mid+small (full 8B).
- **AGENTS.md:70** (S1 #1): recovery line `llm-alloc small-rag auto` →
  `sudo systemctl start verifier-rag-mid` (or `rag-slot mid`) with the hand-run
  trap spelled out.
- **harvest_system_processes.py**: refresh-card tail "on both roots" → "on all
  three roots"; seed-gpu-policy Option 2 re-derived (serving root first).
  Re-harvested + reseeded ×3; system_processes live on all roots, staged-vs-live
  ALL PASS ×3.

Held (PM decisions, not mine): install_rag_full_service.sh gpu0-vs-unit (item #15),
8B/full-root take-down. Open list now: clobber-writer auditd rule (optional),
research_agent/AGENTS.md phrasing (separate tree), 05:12/05:59 staged-rewriter
mystery, live `rag-slot small`→`mid` swap test (optional), `--print` format quirk
in harvesters (harmless).

## ~14:05 — install_rag_full_service.sh brought current (commit `040008a3`)

PM: "update it" (after explanation of its 3 defects + production use-cases).
EDIT mission to qwen-coder, 8-clause spec, diff reviewed + verified
(`verify/install-full-service-gpu2.20261002T140403Z.txt`):
- `GPU=0`→`GPU=2`, header + VRAM comment gpu0→gpu2, health check
  `selected_gpu: 0`→`2`
- Conflicts preflight grep now matches the one-line two-peer form
  (`^Conflicts=.*verifier-rag-mid.service.*verifier-rag-small.service`)
- boot-default comment + port-clear now know mid (stop mid + small)
- `MIN_FREE_MIB=34000` unchanged — still correct (gpu2 ~47 GiB free after
  mid stops)
- RAG.md:927 "34 GiB free on gpu0" → gpu2
Context: PM ruled NO 8B/full take-down (#2 stays parked), so the full root is
a permanent rollback path and this script is its guarded variant (VRAM
preflight + end-to-end query proof — the things `rag-slot full` lacks).

## ~14:30 — install_rag_full_service.sh documented in the well (commit `484559fd`)

PM: no swap test; add the script to the system_processes well. AMENDED the
existing `rag-service-management` card (service management is its home; well
stays 5 cards) rather than a 6th card. Card now covers: what it does
(idempotent install of verifier-rag-full.service; stops mid+small; kills
orphan small_service.py PIDs — waits on the PROCESS, not the port;
34,000 MiB gpu2 floor; verifies /health AND a real table_recipes query;
deliberately not enabled), how (sudo bash ...), when (first install; guarded
mid→full on UNKNOWN box state vs `rag-slot full` on known-good; :8765
orphan-PID recovery; NOT boot/seed/restart; back via start mid). Also fixed
two stale claims found in the same card (installed copies verified
2026-10-02 — not "after the next sudo cp"; placement is per-unit ExecStart
--device, the .d drop-ins are gone) — same drift class as the sweep, missed
by the audit because they live in card text. Re-harvested + reseeded ×3,
staged-vs-live ALL PASS ×3, live probe score 8.19 with all new fragments.

## ~15:00 — install_rag_full_service.sh documented in the well (commit `484559fd`)

PM: no swap test; add the script to the system_processes well. AMENDED the
existing `rag-service-management` card (service management is its home; well
stays 5 cards) rather than a 6th card. Card now covers: what it does
(idempotent install of verifier-rag-full.service; stops mid+small; kills
orphan small_service.py PIDs — waits on the PROCESS, not the port;
34,000 MiB gpu2 floor; verifies /health AND a real table_recipes query;
deliberately not enabled), how (sudo bash ...), when (first install; guarded
mid→full on UNKNOWN box state vs `rag-slot full` on known-good; :8765
orphan-PID recovery; NOT boot/seed/restart; back via start mid). Also fixed
two stale claims found in the same card (installed copies verified
2026-10-02 — not "after the next sudo cp"; placement is per-unit ExecStart
--device — the .d drop-in dirs are gone). Re-harvested, reseeded ×3,
staged-vs-live ALL PASS ×3, live probe retrieves the new block (score 8.19,
all fragments present).

## ~15:30 — research_agent AGENTS.md:54 (last open audit item) — commit `11872525`

PM approved the proposed revision and said apply. In the research_agent tree
(separate commit, other sessions' files left unstaged):
- "The canonical workstation RAG remains in the target workspace." → "The
  canonical workstation RAG lives in the sibling repo `/data/agentic_trading` —
  this workspace has no RAG of its own." (fossil "remains" → present;
  undefined "target workspace" → the actual absolute path, per the file's own
  absolute-path rule; negative intent kept flat)
This closes the final open item of the 2026-10-02 RAG drift audit — all 35
items now resolved across both trees.
