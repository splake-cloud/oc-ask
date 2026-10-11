
## 2026-10-10 (later) — tierA_wave1 built (commit 48024a0a)

PM adjudicated the plan's open questions: (1) 8 Tier A cards approved, O26 joins the O32
family (not a new one), start with O36/O12/O17/O28 for breadth across 4 classes;
(2) all 6 pilot03 records assigned to training; O15 groups with RA07/RA08 (BPV-00020
work item); RA04 crosswalked against N4/N6 (same incident family, N4/N6 unused);
(3) O18+N13 one conservative family; N15 stays out; (4) /var/tmp evidence persisted to
`training_data/fixtures/source_snapshots/` (17 files, split-separated, hashed);
(5) accounting corrected to 23 pairs/3 SFT; (6) evaluation tightening adopted.

Steps executed: (a) source_snapshots persisted + verified (O12 pre-image 442 lines; O38/O41
code+inputs; O39/O40 evidence extracts with source_line_ranges); (b) split file v2
(pilot03_assignment, conservative_groups, dataset_accounting); (c) tierA_wave1 built:
`training_data/derived/tierA_wave1/` = 4 SFT trajectories + 4 preference pairs + 11 replay
fixtures + 10 verbatim fixtures + manifest + README + check_and_replay.py (PASS).

Key evidence facts: O36 draft has 7 stubs (L147,156,179,187,193,198,204) + "Pin it" at L171.
O12 config.ts diff section = 4 small hunks + `@@ -0,0 +1,1362 @@` at L42; 1373 '+' lines;
1362+1372=2734 matches the measured doubling. O17 = corrected verification doc (permission
deadlock per opencode#14473; poll hit non-directory-scoped route). O28: live data reproduced
both values exactly (MAX=6059.27, spot@1559=6026.73, n=73910, last_hhmm=1559).

Accounting after wave1: 27 preference pairs, 7 SFT trajectories, 0 dev, 0 final.

Next (PM-directed): Tier A wave 2 (O13, O12-remainder? — PM said start with the first four;
remaining Tier A = O13, O26, O30), then Tier B (16 text cards), dev set (7 families), final
set (10 families + freeze).

## 2026-10-10 (later): dev set + tierA_wave2 built

- **Dev set COMPLETE + pushed (ad960d44)**: 7 cases, one per dev family, under
  `training_data/derived/dev_set/`. 3 executable (O38 repair, O41 slice-probe, O39
  diagnosis — deterministic checks in check_dev.py) + 4 semantic (O40 honest-fail, O2
  taxonomy, O7 era labels, O10 rollout report — required/forbidden element rubrics in
  dev_scoring.md). Three scoring layers kept distinct: PERFORM / INTERPRET / COMPLETE;
  equivalent commands accepted. `--sanity` PASS (environments discriminate; O39
  reproduces the historical FAIL verbatim); historical post-repair artifacts pass all
  deterministic completion checks. O38 needs a synthetic input parquet (labeled); O41
  uses the historical 9,196-row probe input; O10 env is a labeled reconstruction (v1
  receipt never committed — every fact verbatim from the corrected receipt).
- **tierA_wave2 COMPLETE + pushed (ce03f09e)**: 4 cards (O13 sealed-target FAIL, O19
  watchdog elimination, O26 volume-vs-OI data check, O30 KA at ratified grain). Same
  contract as wave 1; preference format v2 (messages_prefix + chosen/rejected +
  split_index). Env snapshots of persistent density data (labeled): density_long 2024
  first 25 days (O26), concentration_paths year=2024 full (O30). O30 counts
  replay-verified: 37,836 ratified 5-min / 189,205 1-min (at-time 38,098/193,255 on the
  2026-08-09 data state — pool drifted slightly; lesson is integer-independent).
  check_and_replay.py all PASS.
- **Dataset accounting now**: 31 preference pairs (12 pilot01 + 5 pilot02 + 6 pilot03 +
  4 wave1 + 4 wave2), 11 SFT (3 pilot02 + 4 wave1 + 4 wave2), 7 dev, 0 final.
- **Next**: Tier B (16 text-comparison cards) → final set (10 families) + freeze.

## 2026-10-11: Tier B built + FINAL SET built + FROZEN (commit c8f52f2b, pushed)

- **tierB COMPLETE + pushed (adf391c7)**: 16 text-comparison cards (bank/receipt/
  session-grounded) in `training_data/derived/tierB_text_comparisons/`; corpus-field
  identity verified (7 fields × 16 records vs organic_seeds_v2.jsonl). Accounting:
  47 preference pairs total.
- **FINAL SET COMPLETE + FROZEN (c8f52f2b)**: `training_data/derived/final_set/` —
  12 final-split cards → 10 families, one original-context case per family. 5
  deterministic completion checks (check_final.py: o22_o25 4-row join/no-1399,
  o27 forward-ASOF gap slice, o31 vacuous-gate empty=REFUSED, o33 183/189 population
  check, o37 fail+{doctrine,hypothesis}) + 5 semantic (o8 confounding, o11 finding6,
  o23 scope-vs-trace, o35 verify-or-label, o42_o43 config scope + running-process
  diagnosis). At-time boundaries enforced: o42_o43 env excludes the verification
  POSTSCRIPT; o37 expected verdict withheld; o35 resolved DOI withheld (provenance
  only). --sanity PASS (5 environment-discrimination proofs; reference solutions pass
  their own checks; the defective backward-ASOF and legacy vacuous gate FAIL theirs).
  Verify: verify/final_set_final.20261011T012326Z.txt.
- **FREEZE recorded** in organic_seeds_split_v1.json evaluation_record (version 3)
  BEFORE any model result inspected: case list (family/card/case id/input hash),
  scoring criteria verbatim, criteria_hash c30f3967..., frozen_at 2026-10-11T01:26Z.
  Held-out but NOT blind (PM has seen incident summaries; freeze stops criterion drift).
  input_hash = sha256 over env/<case>/ files EXCLUDING reference_solution/ (answer key
  hashed separately as reference_solution_hash).
- **O35 fwg evidence resolved**: card cited host-side /data/seat/fwg/piagent/sessions/;
  in-container path is /fwg/piagent/sessions/ (same store, different root) — verified
  from host vantage (docker exec seat-fwg), L155-166 extract snapshotted to
  training_data/fixtures/source_snapshots/final/O35_fwg_doijoin_resolution/ (404 on
  guessed DOI 02091 + self-catch at L158-159 + resolved record 02072 at L161-163).
- **source_snapshots/ committed** (previously untracked gap, 828K/22 files): prior
  training/development snapshots (O12, O38/O41, O39/O40) built 2026-10-10 but never
  committed + final/O35 + manifests.
- **Delegation**: final_set build dispatched to qwen-coder (BUILD envelope over the
  construction spec .ai/final_set_construction_spec_20261011.md) + 3 follow-on EDIT
  missions (case-id alias fix; 2 dropped env files: o37 review_rubric.md + o42_o43
  next_use.md; 2 byte-level defects: o11 reconcile excerpt 'last error:' colon — my
  spec typo, delegate copied it faithfully; o31 environment_files dir-as-file). All
  bounces verified by me via verify-run; 6 verify transcripts committed.
- **Dataset accounting now (split file v3)**: 47 preference pairs, 11 SFT trajectories,
  7 dev cases, 10 final cases (frozen). Construction of the full pilot corpus is
  COMPLETE for all three splits.
- **Next (PM-directed, from 2026-10-10)**: checkpoint/template conversion check BEFORE
  training, once the exact training model is selected (does not require occupying all
  three GPUs). SFT training prep is a parallel thread (see
  2026-10-11_qwen38_27b_sft_training_prep.md — canary built, GPU naming by hand).
