# 2026-10-17 — Qwen3.6 tuning: demonstration pipeline complete

Thread: LoRA fine-tuning prep for Qwen3.6-35B-A3B (target :8081 model) against the
failure families from the 263-session audit (grounding-by-assumption, verification
decoupling, incomplete propagation).

## What was built/decided
- Step 1 (demonstration) COMPLETE + PM-verified: `analysis/qwen36_tune-2026-10-16/dev_demos/`
  — headless-pi rollout harness (guards in force), fixtures A_v1/A_v2/B/C, truth.py
  recompute, contamination check, stage verifier (A=perform / B=use / C=propagate),
  chat-form renderer. All three stages have a genuine accepted teacher rollout
  (A_v2_1, B_1, C_1); A_1 = genuine v1 teacher failure, retained. 10 records,
  10/10 verdicts, PM sweep: `verify/qwen36-devdemos-sweep2.*.txt`.
- Step 2 (generator) SPECIFIED: `analysis/qwen36_tune-2026-10-16/01_generator_spec.md`
  (FINAL). Step 3 (LoRA run) blocked on a free 96 GiB card.
- PM rulings implemented + demonstrated (2026-10-17): C check = grounding property
  (accurate-and-labeled fields pass; mislabeled/fabricated fail); B grounding = oracle
  match AND computation link (line + command evidence; string match insufficient);
  A fixtures must identify the target via task+metadata (patterns alone insufficient)
  — fixture A versioned A_v1/A_v2 with probe_map.json.
- Full handoff: `analysis/qwen36_tune-2026-10-16/HANDOFF.md`.

## Key facts settled
- Rollouts = headless pi (canonical cmd, cwd repo root, fresh --session-dir) — NOT bare
  API loops (delegate-guard blocks that path; data must match the guarded surface).
- pi project extensions load ONLY from <cwd>/.pi/extensions (no upward walk).
- :8011 is the only live Qwen3.8 seat; it stalls with EOS-mid-thinking — fixed by
  sliced missions + minimal thinking + checkpoint discipline.
- Builder self-block: delegate-guard string-matches the whole bash command → @file
  prompts for nested pi launches containing curl strings.
- csv.writer defaults to CRLF — fixture generators must use lineterminator="\n".
- Generators/seeds live in /tmp/qwen36_tune_dev (ephemeral — durability decision open).

## Open / next
- Build the generator per spec (sliced delegate missions; first batch 10×3).
- Generators/seeds durability location (out-of-tree vs in-tree + contamination update).
- A_1 cross-version pairing policy; training config spec; eval spec (spec §8).
- GPU slot for the training run (don't evict in-flight SFT; check nvidia-smi host-side).
