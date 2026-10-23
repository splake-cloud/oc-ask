# Form-T activity-log incident holdout — FROZEN 24 final + 6 dev (2026-10-21)

**FROZEN** (`training_data/derived/formt_incident_holdout_20261021/`): the second
Form-T eval holdout — the **activity-log incident domain** (operational artifacts),
complementing the frozen public-data holdout. Source: 8 0DTE fly study reports
(`studies/0dte_fly/`) + 22 validator reviews (`.ai/reviews/ai_review_*.md`).

**Pipeline:** 30 candidates (PM-reviewed, per-tranche :8012-verified, with repairs:
ST-01/ST-05 population context, RV-03 closer-lure replacement, RV-02 receipt fix,
RV-08 distinctive-finding swap after a boilerplate shingle hit, RV-13 PASS_OR_FAIL
line, RV-22 table header) → **disjoint screen 0 hits** (A/B/C vs 175 train + 33
real17 tasks + 13 real17 artifacts — the real17 boundary is 13 distinct source
artifacts extracted from 33 task captures on branch
`adjudicated-sft-export-20261019`) → **blind re-key :8012 (records-only): 28 KEEP /
2 REJECT** (ST-01, ST-05: author NE, :8012 AN) → **PM adjudication: restored as NE
per ratified worked example WE-NE2** (asserted value = recorded adjacent statistic
⇒ NE under the strict-logic standard; :8012 applied the reviewer-natural AN reading
against the ratified standard) → **split (measurement-goal ruling): all 7 NE
incidents → FINAL, dev AN/E only** → **FREEZE PASS 12/12 gates** (F1–F8: disjoint
union, file alignment, no record text spanning, manifest sha, label-free inputs,
survivor subset, verbatim + key-exact, input_sha recompute).

**Frozen:** FINAL 24 (SEALED) = 7 NE + 8 AN + 9 E; DEV 6 = 3 AN + 3 E.

**Key design facts:**
- One proposition per artifact ⇒ every packet a unique incident ⇒ no repeated
  samples anywhere in the set; the "repeated samples measure stability, not
  diversity" failure mode can't occur (unlike the public-data holdout). Hence all
  NE incidents go to final (dev is burnable; spending a one-off NE incident on
  calibration strictly reduces final coverage).
- NE section = **two shapes, 7 incidents**: added-silent-element (RV-01/02/03/09/15)
  + missing-statistic-with-recorded-adjacent-value (ST-01/ST-05). ST-01/ST-05 are
  the **boundary-hard** packets (a strong model may call AN; under the ratified
  label that is a mismatch — they measure standard-conformance at the NE/AN
  percentile boundary).
- Blind-rekey mechanics: label-stripped inputs (proposition + records only, no
  source path/state/key), randomized order seed 20261021, 3×10 batches;
  rekeyer instructed no file access, records-only. **Compare-script bug caught
  live:** first run reported 0/30 "KEEP" — author states stored abbreviated
  (E/AN/NE) vs :8012 full forms (ESTABLISHED/…) → mechanical total mismatch;
  fixed with a normalization map → 28/2.
- PM mechanical check independently confirmed 30 packets / 30 keys / 7-11-12 mix /
  byte-exact keys + source lines.
- Standing re-key rule held: author ≠ :8012 → reject, no auto-reinstatement; the
  PM override is a *documented adjudication* (citing the ratified worked example),
  not an auto-reinstate. Raw mechanical outputs preserved untouched.

**Transcripts:** `/tmp/verify_runs/incident-disjoint-screen.log`,
`/tmp/verify_runs/incident-freeze-gates.log`. **Files:** STATUS.md,
FREEZE_MANIFEST.md, REKEY_ADJUDICATION_20261021.md, split_incident.py,
verify_freeze_incident.py, screen_incident*.py, rekey_* (batches/manifest/out/
comparison/survivors/rejects), REVIEW_RECEIPT_8012_{study,study_repair,
review_batch1,review_batch2_3}.md, worked examples (4, PM-ratified).

**Sister card:** `2026-10-21_formt_fresh_public_data_holdout.md` (public-data
holdout, FROZEN 24+25). Train pool: 175 packets, `formt_master_all_packets.jsonl`.
