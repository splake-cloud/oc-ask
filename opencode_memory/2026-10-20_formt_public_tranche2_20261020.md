# Session receipt — 2026-10-20 · Form-T tranche 2 pilot (SQuAD 2.0 near-miss + ClaimVer)

Thread: extend the Form-T public pipeline (after `formt_public_tranche_20261020`,
committed `40678bdce`) with a second tranche from SQuAD 2.0 near-miss pairs and
ClaimVer triplets, as a **separate public-data diagnostic set**.

## Outcome

**DONE.** 56 authored packets → **51 after blind re-key**, committed
`dff089788` (`training_data/derived/formt_public_tranche2_20261020/`, 73 files).
Final states: **15 NE / 14 AN / 22 E** (SQuAD2 30 = 15 matched same-paragraph
pairs; ClaimVer 21 = 11 ne / 5 con / 5 sup).

## Key facts settled

- **Funnel**: SQuAD 130,319 → 43,492 unanswerable → 40,222 near-miss
  candidates → 120 shortlist → 92 KEEP/28 REJECT → 17 selected. ClaimVer
  3,400 → 2,215 single-claim → 938 class candidates → 120 shortlist → 52
  KEEP/68 REJECT → 22 selected. Full ledger of all 240 screened candidates:
  `candidate_ledger.jsonl`.
- **Re-key 51/56 (91.1%)** by qwen3.6-35b on label-stripped batches. The 5
  rejections are ALL one class: **near-fact boundary rows** (tempting record
  redirects one element — person/role/scope/part — of the asserted fact):
  attribution redirect (Dreyfus), role assignment (Grierson/Lassen),
  part-whole (Appalachian 1,500 mi), one-step entailment (only primates),
  compound proposition (color models). 4 flips were NE→AN, 1 was AN→NE.
  Every clean row (all E controls, all direct-swap ANs, clear NEs) agreed.
- **E-control strategy that worked**: screen for E-candidates against the
  *publisher's claim* yields almost nothing (ClaimVer claims are long
  sentences their own triplets under-cover). Instead **author the E
  proposition from the triplets** (a clean declarative the triplets fully
  settle) — 3 of 5 E rows were even selected from screen-REJECTED rows on
  this basis (screener rejected the publisher claim's unsupported parts).
- **ClaimVer packets show triplets only** as records — the source text is
  excluded because the claim is a span of it (would make every claim
  trivially established by its own text).
- **Pairing kept out of packet provenance**: `near_miss`/`pair_control` role
  would leak the control's state (E by construction); pairing lives in
  `pair_map.jsonl` only.
- Screened vs **all 249 existing packets** (public_evidence 50+50, tranche-1
  113+10, batch2 frozen 26): zero source-ID and text-overlap hits.
- Training decision (pilot_report.md §5): **yield justifies a full tranche**,
  with two strictness amendments: (1) redirect-class near-facts — key AN when
  implicit exclusivity is tight, or drop; don't key NE expecting agreement;
  (2) no compound propositions in NE/AN rows.

## PM correction (2026-10-20, standing — do not relitigate)

- **qwen3.6-35b (:8081) is the SAME FAMILY as 3.8** — a non-thinking instruct model. It is good for non-judgment checks only. It is NOT an "independent model" for judgmental work like 3-state re-keying. The re-key gate in both tranches (17 + 5 rejections) was therefore a weaker judgmental signal than the doctrine's wording suggested.
- **:8012 (qwen3.8-27b, qwen38-reviewer) is the correct judgment seat**: same model as :8011 but a different tune and fresh context — that IS the independence. Do not second-guess or re-derive this; PM has stated it six times.
- **:8012 judgmental re-key DONE (same day)** — 73 rows (51 final + 22 rejected), `training_data/derived/rekey8012_20261020/` (VERDICTS_20261020.md, verify-run `rekey8012-compare`). T2-final51: 47/51 agree, 4 splits (all implicit-contradiction boundary class; :8012's explicit-contrary standard). Rejected-22: 12 author-side (all 5 T2 rejections — 3.6 was the outlier 5/5), 9 reinforced, 1 three-way (FT-C251-nda-7 → drop).

## PM decisions APPLIED (2026-10-20 evening, continuation seat, committed `240b94c2f`)

All four pending verdict decisions resolved by the PM and applied in one
idempotent pass (`apply_pm_decisions_20261020.py`, verify-run
`formt-decisions-20261020` 7/7 PASS, receipt
`rekey8012_20261020/DECISIONS_APPLIED_20261020.md`):

- **Reinstate all 12 author-side rows** as authored (7 T1 + 5 T2).
- **Adopt the :8012 explicit-contrary standard** (Option A) for the 4 split
  rows: `FT2-SQ-1a2d034a` pair **dropped** (both legs NE — "By 1994" establishes
  neither "in 1949" nor "in 1994"); `FT2-SQ-1a2d0f34-NM` + `FT2-CV-3264`
  **re-keyed AN→NE** (now core-target NE rows: related-but-insufficient).
- **FT-C292-nda-17 re-keyed ESTABLISHED** (2-of-3 seats; "may maintain one
  copy" = permission; hedged proposition).
- **FT-C251-nda-7 drop confirmed** (already rejected; no change).

Result: **master 164 → 175** — T1 train 103→111 (41 NE / 43 E / 27 AN),
T2 51→54 (21 NE / 21 E / 12 AN; SQuAD2 32 = 16 complete pairs; ClaimVer 22).
Note: the 4 T2 reinstated near-misses restore 4 complete pairs (their PC
controls were already in the final set). Handoff + READMEs updated; first
commit of the rekey8012 work product + handoff + inventory tooling. Pushed.

**Standing rule for the full tranche (ratified): AN requires a record that
explicitly contradicts; a related-but-different fact is NE.**

**gate113 (same day, evening) — coverage-gap re-key of the accepted 113.**
The 73-row :8012 pass covered the 51 T2 final + 22 T1-*rejected* rows; the
113 accepted T1 packets (103 accepted train + 10 frozen eval) had passed only
the 3.6 consistency gate. gate113 blind-re-keyed the exact 113 model-facing
packets on :8012 (12 label-free batches, leak-checked; outputs re-derived from
transcripts, order-verified 113/113).

**Result: 107/113 AGREE, 6 SPLIT (all train-pool), 0 three-way. Frozen 10:
10/10 agree — freeze preserved byte-identical, no versioned eval keys needed.**
The 6 splits (recorded, not applied): `FT-A890` + `FT-A1958` (authored E by
component-assembly — record supports parts, not the compound proposition;
clearest training-harm candidates), `FT-V5ebe6f30…R` + `FT-C146-nda-15`
(explicit-contrary standard — :8012 correct), `FT-C503-nda-19` +
`FT-C623-nda-4` (genuine borderline). PM adjudication open only if the 6 are
to be re-keyed. Files: `rekey8012_20261020/gate113_*` + `GATE113_REPORT_20261020.md`;
verify `verify_gate113_20261020.py` 16/16 (`/tmp/verify_runs/gate113-verify.log`).
Commit `99432619f` (pathspec-only, 32 files, Agent-Print), pushed.

**gate113 fixes (same day, PM: "go ahead and fix them").** The 4
non-borderline splits re-keyed to the :8012 states: A890 E→NE, A1958 E→NE
(component-assembly), V5ebe6f30…R AN→NE (explicit-contrary standard),
C146 NE→AN (record [3] explicit use/disclosure carve-out). The 2 borderline
rows (C503 AN/E, C623 E/NE) stay as authored — open PM item. T1 train states
41/43/27 → 43 NE / 41 E / 27 AN; master 67/67/41 → 69 NE / 65 E / 41 AN.
Idempotent applier `apply_gate113_fixes_20261020.py` (re-run = byte-identical
no-op); receipt `rekey8012_20261020/GATE113_FIXES_20261020.md`; verify
`verify_gate113_fixes_20261020.py` 30/30. Commit `2140ae1d8`, pushed.

## Open / next

- **gate113 borderline 2**: C503-nda-19 (authored AN vs :8012 E — "unless
  otherwise provided" carve-out vs dominant clause) and C623-nda-4 (authored E
  vs :8012 NE — "on behalf of the Alliqua Entities" vs "purposes stated in
  Agreement") — PM call; as authored until then.
- Full tranche at higher shortlist volume (same pipeline + own train/eval
  split) — PM call; the 54 packets stay the diagnostic set, not the training
  pool; use the ratified explicit-contrary standard.
- claimcheck-bench still reserved for the separate success-claim verifier
  experiment (unchanged).
