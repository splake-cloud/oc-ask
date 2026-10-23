# 2026-10-18 — Qwen3.6 :8081 seat fix (F4 window revert + F1 self-contained cards)

**Workdir**: `/data/agentic_trading/.ai/qwen36_seat_fix_20261018/` (full session history,
pre-change parameter baseline, snapshots, proposals, smoke transcripts).

## Built / decided
- **F4: DONE then REVERTED (PM ruling, same day).** `--parallel 2` was reverted to the
  single 262144 window (commit `e8f5b16d8`), verified byte-identical to the 09-06 command,
  confirm-by-use NEGATIVE ("the parallel didn't fix it" — exonerated as the regression
  cause; the fix was F1). PM then ruled "now revert F4 to give parallel back": **2×196608
  is the confirmed configuration again** (the 09-30 baseline doc's "not yet confirmed by
  use" caveat is retired). All 11 surfaces restored to 09-30 values (9 byte-identical,
  models.json surgical one-line to preserve another seat's uncommitted eval-8911 block,
  baseline doc + amendment), live unit swapped, restarted ~5s healthy, checker 28/28 ON
  BASELINE, /slots `[196608] x 2`, all four client lanes 196608.
- **F1 DONE** (PM approved 21:57: "proceed, not usable in the current condition").
  The qwen-coder and fast-coder pi cards are now **self-contained binding contracts**
  (posture, exit-condition-first, key/hash rule, spec-conflict→BLOCKED, probe budget,
  git carve-out, check preservation, semantic boundary, exact exit forms). Root cause
  they fix: pi-subagents sets `noContextFiles: true` → **AGENTS.md is never loaded in a
  subagent session**, so the old cards' "binding in full" references were false premises
  and the effective contract was whatever the model happened to load. AGENTS.md's
  "auto-loads" paragraph replaced with the verified truth. AT commit `d1bfc1a47`,
  RA commit `6672cc1e`, receipt `29a95713a`. `~/.pi/agent/agents/fast-coder.md` is now a
  symlink → RA canonical (was a byte-identical twin).
- **Smoke 2/2 PASS** (live missions through the new cards): qwen-coder BUILD 10.2s —
  spec exact, exit form (a) with quoted proof, zero scope creep; fast-coder EDIT 11.2s —
  9-field final form, verbatim diff, byte-preservation verified. Transcripts in workdir.

## Key facts settled
- llama.cpp without `--parallel` runs `n_parallel auto=4` + `kv_unified`: `/slots` shows
  4 slots each advertising the full 262144 pool (they share it — the documented pre-09-27
  layout). Checker asserts per-slot n_ctx == 262144, not slot count.
- `~/.pi/agent/models.json` is a symlink to `/data/agentic_trading/.pi/models.json`
  (since 09-06) — one file, not two.
- **Mandate iterations F1.1/F1.1b/F1.1c/F1.1d** (all 2026-10-18, commits a0088e2b4 / 4c16326e / e3c6855b4→7402f902c / 42367f6c4+AT profile 6fd293b65…): verify-don't-infer lanes, UNVERIFIED escape valve, per-claim pairing, tool-generated diffs, clause coverage, cross-check against a second observable, **intent-is-not-state (V8)**, **no-silent-degradation (V9)**. PM acceptance case (GPU/model-inventory): run 1 exposed V9 (identities hedged, RAG pid mislabeled); **run 2 PASS** — RAG = qwen3-embedding-4b + qwen3-reranker-0.6b from live process environ (the exact reported failure), all identifications spot-checked vs config.json/cmdlines; cost 42 calls/35s vs 5/14s.
- **PM 2026-10-18 → model profile V5/V6** (`docs/model-kb/qwen36_35b_coder_delegate_profile.md`,
  `a072ab789`): V5 compliance-under-demand (model corrects sequence/judgment errors when a
  verified result is required → requirement must be standing in the card); V6
  partial-verification evasion (verifies part, infers the rest, quoted output rides over the
  whole claim → per-claim pairing, uncovered remainder scored unverified). Both PM-caught;
  ANSWERING-lane smoke 3/3 (bait landed on the grader, not the model).
- **Attribution incident (disclosed in receipt):** first F1 commit `ac0c32315` swept in
  19 staged files from the proxy-adapter workstream (`git commit` commits the whole index).
  Fixed via soft-reset + unstage + re-commit (unpushed, worktree untouched). Standing
  lesson: `git diff --cached --name-only` against the intended list before every commit
  when other seats share the index.

## Open / next
- **F3 DONE (2026-10-18)**: clamp was ABSENT from seat-fwg (both users), seat-pax, and
  host user-global — all three talk to :8081 (172.29.0.1). Copied unmodified (byte-
  identical AT/RA canonical; only host-specific path is the evidence log, try/catch'd →
  no-op in containers), sha256-verified `6d8ef89e681a94b7` in all 4 locations. Per-
  session activation: existing container sessions covered on next start.
- **F1 confirm-by-use**: real coding missions on the new cards (smoke ≠ production).
- **F5 + F2 — saved for future follow-up** (PM ruling 2026-10-18). Full pitch +
  pickup checklist in workdir `proposals/f2f5_dispatch_gate.md` — one dispatch-gate
  extension, two gates: F5 (transport, enforce from day one), F2 (content, shadow
  first, enforce only if 1–2 weeks of log data justifies it).
- **Git discipline (PM ruling 2026-10-18, AGENTS.md rule 6a, `6fd293b65` + 6a(a) caution)**:
  THREE index-sweep incidents, all fixed pre-push (audit: no push from this seat; all
  session commits otherwise clean). (1) 19 proxy files → fixed. (2) CHECKPOINT_EVIDENCE.md,
  caught in pre-commit listing and committed anyway → fixed. (3) models.json in-file sweep:
  pathspec commit re-read the worktree, overwriting a cacheinfo-staged blob with another
  seat's uncommitted eval-8911 block → fixed via 16-file pathspec commit + write-tree/
  commit-tree for the blob (`d9465d588` + `1c1150dbe`); eval-8911 restored uncommitted.
  Now binding: **no bare `git commit`** (pathspec form), mechanical cached-set audit,
  no `add -A`/`add .`/`commit -a`, **no push without explicit PM go** (branch +
  cherry-pick), and: a file whose worktree carries foreign uncommitted content is
  committed from the audited index (cacheinfo + write-tree/commit-tree), never via
  pathspec.
- Layer A (fabrication/overclaim pathology) is NOT prompt-fixable — that's the SFT track
  (tune-demo in progress; see 2026-10-17_qwen36-tune-demo.md). If F1 doesn't move the
  needle on real missions, the remaining lever is SFT, not more prompting.
- Rollback: `git revert` the F1 commits per repo + restore `smoke/pre_f1_fast-coder.global.md`.
