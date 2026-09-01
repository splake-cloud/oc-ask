# 2026-09-01 — OPEX-week study: reconstituted, executed, CLOSED at daily grain

## What happened
- PM objective (verbatim in `studies/opex_week/idea.md`): study options/futures market
  structure + baseline historical stats during opex → predictable tradeable state /
  micro-structure / relative value.
- Original attempt (opencode session "Weekly OPEX inquiry" 08-20, `ses_fdf9ae769ffeuQEr`)
  recorded ZERO messages — its analysis content is lost. The substrate survived:
  `pattern_opex_week` **v2** (2,156 sessions = 23.4%, holiday-correct, built off the
  ATH phase-2a spine `spx_daily_extended`, 9,203 rows 1990→2026-07-20).
- Rebuilt the study properly: `idea.md` + `specs/technical_spec_v1.md` (pre-registered
  P0–P4, 10 bp effect floor, Holm per block, NO-GO bankable) — PM ratified ("go").
- Executed by delegated `pi -p` child on **jett-8011/qwen3.8-27b-fp8** (PM-provided
  collab seat, same model as main seat) via `.ai/staging/opex-week-v1/` (mission.md,
  run.py, transcript.jsonl 15k lines). 959 s, exit 0, G0–G4 all PASS, G2 byte-identical.

## VERDICTS (daily grain — CLOSED)
- **P0 state: NO-GO** (h1 close opex−non −0.027%, sub-floor, p_holm 1.000; h3–h20 same)
- **P1 day-of-week clock: NO-GO** (pre-registered primary)
- **P2 ATH×OPEX 2×2: NO-GO** (h1 ATH=1 opex−non −0.056%, p_holm 0.930)
- **P3 time-to-5% drawdown: MARGINAL** (HR 1.045, p≈7.5e-10 — sub-floor AND flips in
  holdout HR 0.997 → UNCONFIRMED-OUT-OF-SAMPLE)
- **P4 regime conditioning: NO-GO**
- Net: **opex week is not a different tradeable daily state** (1–20d horizons).
- **Exploratory flag (NOT a verdict):** Monday-in-opex-week h1 close +0.189%
  (CI +0.080/+0.300, p_holm 0.006, above floor, holdout same sign) — PM adjudication item.

## Commit
`1580ecfd` on master (pushed). Study root `studies/opex_week/` (scripts/, outputs/,
receipts/ v1_gates + v1_verdicts, spec with as-run hashes).

## Open (PM calls)
1. **P1/P2 primary pinning** — RESOLVED 2026-09-01 (same day): PM ratified the
   child's pinning as the as-run definitions (receipt
   `studies/opex_week/receipts/ratification_p1p2_pinning.md`, commit `2812484a`).
   Ratification confirms what was tested; does not declare the estimands uniquely
   correct. Closed study not amended.
2. **Monday exploratory signal** — confirm-study (pre-registered v1.1) vs dismiss.
3. **fly-gap-horserace re-run** — RESOLVED 2026-09-01 (commit `b0dcbe9b`):
   `scripts/study_fly_gap_horserace_r3_r4.py` now sources `is_opex_week` from the
   `pattern_opex_week` v2 table in research.duckdb (LEFT JOIN + COALESCE 0) instead of
   the input parquet's all-NULL v1.0-frozen column. Re-run stamped to
   `/data/parquet/study_fly_gap_horserace_r3_r4_v2/` (attestation re-stamped).
   Grounding correction: the column was NULL, not mislabeled — no horserace statistic
   was ever conditioned on opex; the fix is label-correctness, proven by old-vs-new
   multiset diff (only is_opex_week differs). Re-run also advanced the sample
   (input panel extended 2026-08-07 → 2026-08-31; 5,110 → 5,159 rows).
   Transcripts: verify/fly_gap_horserace_opex_v2_fix.20260901T1400{13,20}Z.txt.
4. **Phases 2–3 (options OI/volume micro-structure, futures RV)** = data-acquisition
   decision; no such series on this box. Unchanged by v1.
5. Delegated-child mechanics that worked (bank for future): `pi --print --no-session
   --mode json --model jett-8011/qwen3.8-27b-fp8 --append-system-prompt <rules> <task>`
   from /data/agentic_trading; mission+constraints on disk, child reads them;
   60 s smoke-write test before a long spawn; final message = strict table shape.
   Child ran one read-only `git status` against the no-git rule (no-op; noted in
   its own NOTES — add to the mission template: no git at all, not even status).
