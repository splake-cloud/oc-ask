# 2026-10-14 — step_8 fix cycle: D1 re-verified (PASS) + content-≤ snap finding fixed (PASS)

Thread: the 2026-10-13 D1/D2 fix cycle for step_8, continued after the
serialization session (2026-10-14_sft_serialization_verification.md) froze.
Grounded on files (handoff brief 30621591d + HANDOFF_20261013_step8_d1_d2_fix.md),
not on history. Seat jett-8011 (qwen3.8-27b-fp8).

## Settled this session

1. **D1 (records dropped tool_calls / reasoning_content / tool_call_id) — fixed,
   re-run, 8012 re-verified PASS.** `step8_recon.py` now carries full normalized
   messages, asserts task-tail identity on ALL fields, and has a NEW structural
   guard (per-window supervised_post_mask == official's). Run
   `runs/step8_recon_20261014T044258Z`: 52/52 `summary_spliced`, aggregate
   supervised **734,161** (== official per-window; the old 57,854 was
   degraded-form), census 4,324/4,067/3,939 (all zero in the void form), flags
   191/137, leak 0, scope PASS. 8012 review PASS (7 checks,
   REVIEW_8012_20261014.md in the run dir). Commit 7d0a3d87d; step-log row
   ef3f74415 (old recon row marked SUPERSEDED-D1).

2. **INCIDENT (scored, delegate) — R6 rule earned.** A first-pass qwen-coder
   EDIT (correct delivery) ran a git checkout-style command while
   reconstructing its diff baseline; the boundaries file was untracked → no
   git baseline → the command reverted the UNCOMMITTED D1 fix in
   step8_recon.py (04:31:41Z). A recon run 70s later (T043251Z) executed
   pre-fix code → kept as void defective record (byte-identical fingerprints:
   57,854 + 11 windows @ task_start 303,580). Exactly one tracked file
   affected. Restored byte-exact via a one-command git-apply mission
   (patch /tmp/d1_fix.patch; R6-conformant envelope: git mutations banned by
   name, read-only git status final check). New binding rule R6 in the model-kb
   profile (commit a48d81d0c).

3. **`≤`-snap finding (FINDING_20261014_snap_before_content_delimiter.md) —
   verified, adjudicated MATERIAL, fixed, re-verified PASS.** The finding was
   captured pre-freeze by the local model; the pinned
   qwen3.8-27b-bf16 chat_template.jinja (rev 1d4bf0f) contains **zero U+2264**
   → every ≤ in rendered windows is content → `_snap_before`'s `rfind('≤')`
   was pure luck. `_17`: stored view 2,977,976 chars ≈ 3.2× the 262,144
   serving context (server would truncate the task tail — invariant broken at
   the wire) + `judge_view_truncated:false` was a lie (clamp against the
   snap-contracted prior hid the true prior's 800,225-token truncation).
   Blast radius contained: step8_judge.py had zero references to
   judge_boundaries.json — no judge output contaminated. Fix (qwen-coder):
   drop the snap at all 3 sites; exact token-decoded char offsets
   (`len(decode(ids[:k]))` — a whole-token prefix ends exactly on the token
   boundary; BPE-safety holds by construction, the finding's worry was
   unnecessary). Re-run over the official 127 windows + invariants:
   tiling/ordering/flag-consistency/task-fits/view≤262,144 all 127, 0 fails;
   independent split-re-tokenize boundary proof on 4 windows, 0 mismatches;
   `_17` corrected task_start 303,580 → 2,846,688 (the frozen session's own
   item-3 number), flag False → True. 8012 review PASS (8 checks,
   REVIEW_8012_20261014_boundaries.md). Commit 7f3971ef6.

## Operational facts

- **boundaries re-run deadlock**: 16 pool workers × torch 96-thread OMP pools
  under concurrent load → 2 workers frozen in futex, the rest dead, main
  waiting forever (first attempt). Kill by explicit pid only; re-run with
  `OMP_NUM_THREADS=1 TOKENIZERS_PARALLELISM=false` → clean 1907s. Use
  constrained threads for step8_judge_boundaries.py under load.
- verify-run gotcha: pass the command directly; an env-var prefix becomes an
  argument to its `"$@"` (exit 127, honest transcript kept).
- verify-run transcripts live in `/data/agentic_trading/verify/` (step8_recon
  / step8_recon_invariants / step8_boundaries_fix_rerun2+3 /
  step8_boundaries_invariants).

## Next (all PM decisions, none mine)

- **Judge pass + 8012 re-review**: judge model (:8011 vs :8012 vs qwen3.6
  @:8081 — the frozen session's plan had :8012 re-judge the official 127
  "independently of 8011" to break the self-review loop), re-judge scope
  (official 127 / recon 52 / both / a subset), the task-first view
  (HANDOFF §5.2 — not yet wired into step8_judge.py; boundaries
  infrastructure now exists and is verified), length pruning (post-canary),
  GPU canary. Recon ran with STEP8_JUDGE=0 deliberately — a judge run on the
  old 120k-char view would be flawed/superseded.
- Corpus selection from the 179 windows (127 official + 52 recon).
