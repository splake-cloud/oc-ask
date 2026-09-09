# 2026-09-09 — ES auction profile, Phase 4 (profile summaries) closed & ratified

Thread: built and closed Phase 4 of the ES auction-profile study on top of
the P3 384-profile substrate; operator ratified same day.

## What was built
- `studies/es_auction_profile/scripts/va_expand_v1.py` (D1) — pure frozen S2
  Dalton pair-expansion (VAH/VAL), nearest-single-bin stop, tie→UP, lattice
  semantics (absent rows = zero cells).
- `studies/es_auction_profile/scripts/build_profile_summaries_v1.py` (D2) —
  `summary_v1.parquet` 384×35 + manifest (385 hashes); VPOC, concentration
  (HHI/eff_bins/topK/p50/p90/entropy), 35-col deterministic assembly;
  `summarize_file()` public.
- `studies/es_auction_profile/scripts/check_profile_summaries_v1.py` (D3) —
  independent-predicate gates G0–G7, fixtures F-a…F-f, tampers T1–T3, X2/X6/X8.
- Outputs (uncommitted heavy parquet): `studies/es_auction_profile/outputs/profile_summaries_v1/`.

## Key settled facts
- **S2 VA semantics**: pair-addition (winning pair added), not single-bin
  steps; nearest-single-bin only when that one bin crosses 0.70. Operator-
  frozen pseudocode is canonical (spec_v4 §3.3).
- **D5 no-copy**: Summary(P) = f(that profile file); twin equality is
  asserted (192/192), never produced.
- **Errata (transcription-only, PM re-derived):** F-b Σv=24 (19/24); E1 VA
  span bound is [min−1,max+1] (pair step from max−1 can include max+1 with
  v=0 — 12/384 rows, max overshoot 1); E2 X8 fingerprint endpoints full-
  precision.
- **KASA4 (10 semantic rules, read-only card): S1–S6 all CONFIRMED,
  0 CONTRADICTED, 0 BLOCKER/0 MAJOR.** First clean KASA round of the study
  (P2 needed rev 7, P3 needed 3 rounds).
- Battery fingerprint (full precision): va_share [0.700043, 0.712637],
  width [16,984] ticks, entropy [0.835422, 0.972480], hhi [0.000960,
  0.036146], VPOC ties 0/384.

## Model routing settled (OQ1, operator ruling 2026-09-09)
From the pi seat: `qwen38-collab` (:8011, write+edit) carries the
8012-semantic-coder role; `qwen38-reviewer` (:8012, read-only) is KASA;
`qwen-coder` (:8081) is the fast low-judgment lane.

## Where things live
- Contract: `studies/es_auction_profile/specs/spec_v4.md` (blueprint_v4
  alongside); git line f0dd7c5c → c6ae40ff → 3f68b2bb → a95aa801 →
  20a92557 → 008d8770.
- Closure: `receipts/phase4_profile_summaries_receipt.md` (A1–A10 +
  ratification), `receipts/kasa4_adjudication.md` (matrix verbatim).
- Canonical verification transcript: `verify/d3_gate_battery.20260908T221734Z.txt`.

## Open / next
- **Phase 5 — geometry (HVN/LVN/nodes)** on the same substrate; spec not
  yet written. Phase 6 = PIT market context; studies layer above.
- n=1 entropy NULL rule is fixture-covered only (no n=1 profile in the
  battery, min n=57) — revisit if the battery changes.
