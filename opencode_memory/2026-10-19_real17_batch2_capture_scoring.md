# 2026-10-19 — real17 batch-2: three-arm capture + RUBRIC_V2 scoring + repeatable-weakness verdict

## What was built / decided
Continued the proxy-substitution eval (`training/proxy_substitution_first_attempt_20261018/real17_eval_20261019/`). Built a **26-task three-state Form-T deck** (`batch2/`) that cleanly separates `established` / `affirmatively_negated` / `not_established`, then **captured all three arms** (base, pass3, real17final) and **scored per RUBRIC_V2** to answer: *is the P1/P2 (structure vs epistemic-state) distinction a repeatable weakness in pass3/base, and does the continuation adapter fix it?*

## Key facts settled (file paths under `real17_eval_20261019/`)
- **Deck:** `batch2/tasks26.jsonl` + `batch2/KEY26.jsonl`, frozen (`batch2/FREEZE26.json`), leak-screened, answer-leakage-clean, all proposition-embedded quotes verified present in excerpts. Blind deck `batch2/review_keyblind.md`.
- **Capture:** `batch2/capture_batch2_20261019/` — 26×3 = 78/78 CAPTURE_PASS on server :8911 (GPU 1, exact config per `SERVER_CONFIG_r2`: qwen3.8-27b-fp8 + pass3 + real17final LoRA, MTP+prefix-cache+fp8-KV, 262144 max-len). temp 0.
- **Scoring (RUBRIC_V2, 4 dims, 5 pts):** `batch2/scores.jsonl`, `batch2/scoring_workspace.jsonl`.
  - **base (raw) = 130/130 (perfect).** pass3 = 127/130 (underclaims E07). real17final = 124/130 (underclaims E07 + A10).
- **Verdict (`batch2/REPEATABLE_WEAKNESS.md`):** the P1/P2 underclaiming is NOT a weakness in base (raw) — it's a regression the training introduces. The trained arms require the record to *explicitly state* the conclusion rather than making the one-step inference base makes (undefined target → not implementable; operational split → not consistent). **The continuation adapter does NOT fix it — it is marginally more conservative** (130 → 124). Task-set-specific: on the original single-task E08 the continuation read better (`E08_ADJUDICATION.md`).
- **Adjudication (key error):** N02/N05/N07 were frozen as `not_established` but the records make an *explicit finding of the absence* ("schema is not locked", "counts pending verification", "schema form is unpinned") → RUBRIC_V2 counts that as `affirmatively_negated` ("complete enumeration **or an explicit finding**"). Correct composition 9 est / 14 aff-neg / 3 not-est (N03/N04/N06). Supersedes `KEY26.jsonl` for those three (no score change — all arms 5/5 on them).
- **GPU ops (Option A):** stopped :8012 reviewer (pid 2833518, cross-checked) → captured → restarted :8012 (pid 3099199, ready in ~30s). :8012 is live at the end.

## Process lessons (concurrent-edit awareness)
- Two concurrent-edit incidents this session (both caught + fixed): (1) a stale blind deck was handed to the :8012 reviewer → it flagged E07/E09 tokens that a concurrent fix (`cebfab547`, seat `pi`) had already corrected; I first mis-called them "false positives," then retracted after checking git. (2) my commit `3c99a2bbd` reverted a concurrent leakage fix on N03/N04 from a stale working tree. Lesson: **always verify against the exact artifact the reviewer read + check git history before acting on review findings; regenerate the blind deck from the frozen text + sha-verify before any key-blind review.**
- Commit discipline held: pathspec form, `Agent-Print` trailer, staged-set ⊆ intended-set verified mechanically. This session's commits: `4b588f045` (blind deck), `3c99a2bbd` (:8012 findings), `b51d020b7` (key-blind fixes), `c2eb64569` (capture + scoring + report).

## Open / next (PM decision)
1. **PM decides** commit/push strategy (branch `adjudicated-sft-export-20261019` is a stale ancestor of master) + **whether to train** (no training has happened; the continuation adapter does not fix the P1/P2 underclaiming on this deck).
2. Investigate the external deletion of `.ai/coder_bench/transcripts/*.jsonl` (37 files) — the authoritative `data_pool_proposals/*.transcript.json` (186 files) is intact.

## CORRECTION (later same day, 2026-10-19) — the E07/A10 finding is superseded
An independent seat (`codex (gpt-6)`, commit `6ad170e23`) adjudicated E07 + A10 and I verified both claims against the sources — **both hold, and my finding was wrong**:
- **E07 prompt is defective**: its title cues the answer ("retrieval-metadata update not implementable") + the excerpt truncates before the decisive evidence → **held, no score**. My "base 5 / pass3 2 / r17f 2" was confounded by the title cue (base followed it, trained arms didn't).
- **A10 key was wrong**: the review calls the split "not blocking" / "clear enough to pass" (no explicit contradiction) → correct state is **`not_established`**, not `affirmatively_negated`. Under the correct key the direction **flips**: **base overclaims** (affirmatively_negated) on A10 while the **trained arms are more calibrated** (real17final 5/5 temp-0, 3/5 temp-1; base 0/5 both).
- **Corrected conclusion**: 24 tasks tie 5/5; E07 invalid; the one differentiating task (A10) **favors the trained arms (real17final most)**. The "base 130/130 perfect / continuation marginally worse" was an artifact of my wrong A10 key + E07's title cue. It does NOT establish a margin in either direction.
- Artifacts: `batch2/ADJUDICATION_RECONCILIATION.md`; `REPEATABLE_WEAKNESS.md` + `RELIABILITY.md` now carry a SUPERSEDED banner.
- Lesson banked: a "finding" that survives only under a key I authored is not a finding until the key itself is checked against the source — the key was the defect. The leak screen checked 8+-word doc overlap, not answer-bearing packet titles (the E07 gap).
