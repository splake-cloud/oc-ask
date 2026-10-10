# 2026-10-10 — Pilot dataset assembly plan delivered

## What happened

PM checkpointed the pilot02 batch at `9f6896eb` (closed, no more edits) and
directed the next pass: (1) broaden training coverage from unused training
families (evidence-finding decisions preferred; no more O20/O29 variants),
(2) construct dev + final eval cases with observable actions + scoring
criteria, freeze the final set before inspecting model results. No GPU
training; template checks wait for the model selection.

Deliverable: `.ai/pilot_dataset_assembly_plan_20261010.md` (commit `48be97bd`,
pushed). Plan only — no construction started; awaiting PM adjudication.

## Key findings in the plan

- **Usage ledger**: 25/37 training cards untouched. pilot01's 12 parents all
  verified in the training split (no dev/final leak). Untouched: N1 N2 O4 O36
  (IF); O6 O28 O30 N3 N4 N5 (RC); N8 (RCal); O12 O13 O26 N9 (EGR); O15 O16
  N11 N12 (PV); O17 O18 O19 O21 N13 N15 (DA).
- **Overlap flags**: O15 = BPV-00020 work item = pilot03's pending
  F-RA07/F-RA08; N15 must stay with held RA12; O18 and N13 are the SAME
  session (09-29 01a0eb87) — different incidents, related-not-identical;
  RCal training pool has only one untouched card (N8).
- **Selection tiers**: Tier A (replayable, evidence-finding): O36, O12, O13,
  O26, O28, O30, O19, O17. Tier B (bank/receipt text): the other 15 (N15 out).
- **Dev set** (7 families): observable actions + criteria per family; O38/O41
  (jul12_code_repair) and O39/O40 (sqlmesh_verification) merged.
- **Final set** (10 families): same design; freeze protocol = record case
  list + criteria + hash in split file's evaluation_record.freeze BEFORE
  inspecting model results.
- **Blocking dependency**: five ephemeral /var/tmp stores back dev evidence
  (run_20260712_v13_full_r5, run_20260712_v15_sliceprobe, cl_tick_entry1,
  cl_tick_entry3, apply-port.py.pre-per-task-deadline.20260930) — all present
  today; PM must name a durable destination before dev construction.
- **Data-quality note**: bank lines 218/228 (INT-0218/0228) cite ruling_receipt
  `studies/credit_fly_open_anchor/...` which does NOT exist; the actual receipt
  is `studies/credit_fly_opening_range/receipts/pm_ruling_2026-09-30_idea_review.md`
  — the same receipt F-RA04 (pilot03) uses. Bank path drift, flagged.

## Open questions for PM (in plan §7)

1. /var/tmp persistence destination? 2. Tier A approve/add/cut? 3. O18/N13 as
   one family or two records? 4. pilot03 assignment (pending since round 3)?
   5. RCal breadth — accept 2 or source a third? 6. N15 hold confirmed?
