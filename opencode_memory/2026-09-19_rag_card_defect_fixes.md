# RAG card-defect fixes + 9-collection seed (2026-09-19, pi seat jett-8012)

Thread: 7 pending RAG collections from dead sessions → audit → fix → seed.

## Verdict
All 9 pending collections SEED (nothing abandoned): data drift + new ES pool
registration + verified dead-session harvester edits. Audit (8011,
`verify/rag_seed_card_audit_8011.md`): 46 changed cards → 41 accurate, 5 inaccurate.

## The 5 defects (all harvester bugs, all fixed)
1. `harvest_outputs.py` sibling-parquet copy: a lineage's card text was keyed to EVERY
   parquet in its directory → **164 phantom cards** (cot_disaggregated carried cot_tff's
   1960; every per-contract front-month parquet carried the pool's 5.5M-row card). Fix:
   lineage card only when the lineage references the parquet (output_parquet/stem);
   unreferenced siblings get a minimal probed card (name + row count).
2. `unit_for()` system-scope only → `paper-retrieval.service` (USER unit, added 09-17)
   read as "no systemd unit, reparented to PID 1". Fix: `--user` fallback + `scope` field.
3. `systemctl is-active`/`is-enabled` non-zero exit (inactive=3) misread as `probe_failed`.
   Fix: printed state word authoritative (`_STATE_WORDS`).
4. rag-service owner hardcoded `verifier-rag-small` while :8765 moved to
   `verifier-rag-full.service` at the 09-17 cutover. Fix: owner from listener PID's
   `/proc/<pid>/cgroup` leaf unit (`owning_unit()`).
5. model-endpoints "serves model id 'None'" for :8080 (ComfyUI) / down :8081. Fix:
   3-way — model id / answers-no-model / probe-REFUSED (backend DOWN). PM: :8081
   deliberately down, temporary — card now accurate in both states, self-corrects on
   restart.

PM-review catch on 8011's diff (2 inherited wording defects fixed by me): n_claims
"GET /status failed" when the probe SUCCEEDED (service reports null); `listening()`
IPv6-tailnet line clobbering the loopback process name.

Left as-is (defensible): `es_1min_front` "data 2010-06-06" = `ts_event_et` min
(2010-06-06 18:00 session start for trade_date 2010-06-07), not a hard error.

## Pipeline facts (for next time)
- `seed.py` runs `--recreate`: full drop+refill — stale/phantom cards are REMOVED on
  re-seed, not just upserted.
- `scan-stage` fingerprints WATCHED INPUTS, not harvester code → harvester-code edits
  need `scan-stage --groups <g> --force`.
- Full-root seed: `seed-pending --root full --remote-embed http://127.0.0.1:8765/embed`
  (embeds on the RAG card, zero local GPU). Small root: local 0.6B, needs 4 GB free.
- This run: 9 collections / 6421 chunks per root, both roots, zero pending after.
- Parallelism pattern (PM-requested): background 8011 via
  `setsid nohup pi --provider jett-8011 --model qwen3.8-27b-fp8 --approve --no-session
  --append-system-prompt /home/user/.pi/agent/agents/qwen38-collab.md -p "$(cat mission)" &`
  (pi CLI has no --agent flag) while the PM seat works non-conflicting tasks in parallel.
  Host vantage first (`readlink /proc/self/ns/net` = net:[4026531833]).

## Artifacts
- Commit **2260cbef** (pushed): 6 harvester files (2 fixed + 4 verified dead-session
  edits: build_domain_facts, build_study_infra, harvest_libs, harvest_table_cards).
- Removed gitignored scratch `harvest_sqlmesh_reference.py.bak.20260906T155144`.
- 8011 report: `/tmp/rag_card_fixes_report.md`; pre-fix staged snapshot
  `/tmp/staged_backup/` (both in /tmp — ephemeral).
- Verify transcripts: `verify/rag_card_fixes_pm_verify.20260919T024448Z.txt`,
  `verify/rag_live_index_pm_verify.*`, `verify/rag_retrieval_smoke.20260919T025219Z.txt`,
  `verify/1_harvest_outputs_fix.*`, `verify/4_no_phantom_cards.*`.

## Open
- `verifier-rag-small.service` still enabled-but-inactive (dead owner from the cutover) —
  service lifecycle is a PM call, not touched.
- :8081 (qwen-coder) temporarily down per PM; model-endpoints card will self-correct
  at next scan-stage when it's back.
- `serve_retrieval.py` reports `n_claims: null` in /status (count not cached server-side)
  — service-side quirk, card now reports it honestly.
