# 2026-10-08 — pax seat: grants G1/G3/G4/G5 applied + first real rebuild + hardening pass filed (pi seat jett-8011 / qwen3.8-27b-fp8)

**What happened:** PM granted the paxton research seat's onboarding grants
G1 (repo RO mount), G4 (poppler-utils), G5 (extraction endpoint) to unblock
T1.1/T1.3/T2.1/T4.1; G3 (:8090 paper-retrieval route) granted same session
on PM follow-up. Docker mounts only change at create-time, so the grants
required the seat's first canonical rebuild since the Oct 5–6 ad-hoc bring-up.
All applied and verified; a 3-item hardening pass was filed (runbook §12).

**Key facts settled:**
- The operator's "done" run did NOT take effect (old container still up; no
  root-file mtimes advanced) — container phase run directly via docker group
  instead (all other installer phases idempotent no-ops).
- **pi trap:** live seat ran pi 1.0.0 (in-container npm upgrade Oct 6);
  image `fwg-seat` ships 0.87.1; `pi-research` needs ≥0.99.0 → naive recreate
  = downgrade + broken research stack. Avoided via the seat's own
  `/workspace/bin/restore-after-rebuild.sh` (pi 1.0.0 via npm, BYOK from
  `piagent/.research-config.env.bak`, camoufox from durable tar, locale, tmux,
  Chromium launch-verified, login silence). paxton's live session interrupted
  (approved); all state on disk, resumable.
- **Sentinel guard (H2, DONE):** installer's "reset smoke-test state" was an
  UNGUARDED `rm -rf` over `piagent/{sessions,auth.json,models-store.json,bin}`
  — a re-run would have wiped paxton's history. Now first-install-only, gated
  on `/data/seat/pax/.seat-init-done` (sentinel pre-created before the re-run).
- **Camoufox dead path (H3, OPEN):** `setup-research-stack.sh` checks
  `/data/seat/pax/camoufox-cache-152.0.4.tar` inside the container where
  `/data/seat` is not mounted — can never be true. Restored via
  `sg seat-pax -c 'cat …' | docker exec -i seat-pax …` pipe (1.37 GB).
- **Exec bits (related):** installer's `chmod 640` sweep stripped
  `ws/bin/*.sh` → 3 restore steps failed Permission denied;
  `docker exec seat-pax chmod 750 /workspace/bin/*.sh` fixed.
- **Image:** `fwg-seat-pax` = fwg-seat + poppler-utils (pdftoppm 22.12.0),
  built from `/home/user/seat-pax/Dockerfile.seat-pax` (+ `.dockerignore`
  excluding `snaps/` — keeps the ~15 GB out of the build context).
- **G5:** one-line default swap `127.0.0.1:8012` → `172.29.0.1:8012/v1` in
  `scripts/paper_corpus/extract_claims.py` (L348) + `metadata_extract.py`
  (L62, L409 — same defect, same pipeline; pilot would have died at step 4).
  172.29.0.1:8012 is bound host-side too → host runs unaffected. No CLI flag
  added (grant as requested). Dispatched as 2 EDIT envelopes to qwen-coder.
- Whole-repo RO for G1 (the request's subdir list is the USE scope, not an
  ACL) — PM's request text said "Mount /data/agentic_trading read-only".
- **G3 (2026-10-08, same session):** :8090 routed into the seat — DNAT
  PREROUTING `172.29.0.0/16 -d 172.29.0.1 --dport 8090 → 127.0.0.1:8090`
  + INPUT accept for the DNATed flow (the INPUT accept was ALREADY on the
  host; only the DNAT was missing). Applied via the banked docker-chroot
  root vantage (`--network=host --cap-add=NET_ADMIN`; the flag-order typo
  `-C -t nat` burns once — iptables wants `-t nat -C`). Installer now owns
  both rules idempotently + soft verify check (warn, never fail). Verified
  from the seat: /health server_up + live POST /search returning real
  momentum-crash claims. Subnet-scoped (fwg seat can read too — same
  accepted tradeoff as the RAG rule).

**Artifacts:** commit `9b4a6f58` on master (2 scripts + runbook +
`docs/onboarding/researcher_onboarding_tasklist.md` first commit) +
`be416f06` (runbook §12 hardening pass) + `0057169c` (runbook: G3 GRANTED);
host files `/home/user/seat-pax/{pax-seat-install.sh,Dockerfile.seat-pax,.dockerignore}`
(installer now carries G3 block + sentinel guard);
verify transcripts `verify/g5-extract-claims-endpoint.*`,
`verify/g5-both-endpoints.20261008T141737Z.txt`,
`verify/g1g4-seat-definition.20261008T142019Z.txt`,
`verify/post-recreate-g1-g4-g5.20261008T142721Z.txt` (the one that caught the
no-recreate + pi version), `verify/final-g1-g4-g5.20261008T143838Z.txt`,
`verify/g3-paper-retrieval-route.20261008T163637Z.txt`.
Runbook: §11 pax ruling (grant ledger G1–G5) + **§12 hardening pass**.

**Open / next:**
- **Hardening pass (runbook §12):** H1 bake pi 1.0.0 into `fwg-seat-pax`
  (OPEN — spec'd; fwg has the same shape); H2 DONE; H3 camoufox tar path
  (OPEN — two options, PM picks; edit is in paxton's /workspace → coordinate).
- **G2 (papers_corpus RW)** pending — needs its own ruling (new /data/parquet
  write exception); §7 of the tasklist keeps landing PM-executed anyway.
  (G3 completed this session — see above; the :8090 fallback of reading
  claims JSONL directly is no longer needed.)
- Onboarding doc numbers stale: "28 wells" (live registry: 30), "117 PDFs"
  (library: 121) — not fixed, PM's call (one-line commit).
- `docs/rag_card_paper_retrieval_8090.json` stale: claims :8090 is hand-launched
  nohup with NO systemd unit; `paper-retrieval.service` is enabled+running
  (verified PID/PPID). Will mislead anyone following it for a G3 restart.
- fwg installer template: dropped-`sudo` ForceCommand + stale Dockerfile path
  in its error hint (pre-existing, banked in runbook §11, untouched).
