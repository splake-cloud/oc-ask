# 2026-10-17 — Evidence-judgment batch 3 → 50-example training batch

## What was built
- Assessed the existing 38-packet candidate batch in `training_data/derived/evidence_judgment_batch3_20261017/` (made by a parallel effort): independently re-verified **all 30 public verdicts against the actual decks** (all defensible) and **re-executed all 8 synthetic EXEC programs (8/8 stdout reproduced)**.
- Completed it to the PM-requested **50-example structure**: 6 categories × 8 + 2 weakest-coverage, 3S/3C/2N per-category guide.
- **14 gap-filler packets** selected from the 1,854 remaining resolvable candidates, each re-read against its deck; **2 packets excluded** (SCIFACT-683, FEVEROUS-90104-G0 — the batch3 audit's two "packet/key defect" holds; my independent read: verdicts defensible, generated-text framing overreached; excluded for C3 rebalance, not for label error).

## Key files (all in `training_data/derived/evidence_judgment_batch3_20261017/`)
- `final50_source_packets.jsonl` — 50 model-facing packets (42 public verbatim + 8 synthetic), 0 label leaks
- `final50_reference_key.jsonl` — reviewer-side key (verdict/category/basis/content status)
- `gap_fillers_14_source_packets.jsonl`, `gap_filler_admission_analysis.md` (4-question analysis + dedup flags + gaps)
- `COVERAGE_50.md` — full coverage table, candidate-batch assessment, gap report
- `excluded_packets.jsonl`, `answer_seed_final50_gap14.jsonl` (author input for the 14, not yet run)

## Key facts settled
- **Final composition:** C1 3/3/2, C2 2/3/3, C3 3/4/1, C4 3/4/1, C5 3/4/1, C6 3/3/2, EXTRA 2S → **19S/21C/10N = 50**. Content: 31 approved / 5 held (re-authoring) / 14 pending authoring.
- **Batch3's C5 gap claim was wrong** ("no authentic version cases found"): the pool has a strong version-continuity family. 5 gap fillers come from it: Vukovi mirrors (84549 S / 67038 C), USS Agwidale mirrors (6193 S / 30847 C), Bodnarchuk current-team (35092 C).
- **Deliberate group-level overlaps (disclosed):** 1227/1228 flip pair (same SciFact abstract); 84549/67038 + 6193/30847 same-page mirrors; 47079 (NEI "four models") / set2 22395 (C "six models") same-table boundary pair.
- **Pool NEI is exhausted:** only 11 FEVEROUS NEI candidates exist in the resolvable pool; 8 are now in the batch; 90437 has a suspect gold; 90641 is a same-page duplicate of set2 92686. SciFact NEI is structurally unavailable (112 unlabeled claims have empty evidence).
- **Suspect publisher golds documented:** 90437 (negative-existential NEI vs positive record), 26770/72962 (opposite golds, near-identical claims, same page), 73331 + 81167 (unlicensed name/geo abbreviation resolutions marked S). All excluded from selection.
- **C5 has no NEI** in the pool — reported gap, C5 lands 3/4/1.
- P1E/P2E/P4E (local episode packets in `tui_pool_packets_20261015/`) remain a separate retained pool, not counted in the 50.

## Open / next (needs PM go)
1. ~~DataDesigner authoring run for the 14 gap fillers~~ — DONE (round R2, see below).
2. ~~Re-authoring decision for the 5 content-held pairs~~ — DONE (round R2, see below).
3. TRL label/length inspection of the 44 approved pairs (existing maintained path).
4. PM decisions on the 6 holds (esp. 49011 re-key/replace).
5. No training run authorized.

## Round 2 (2026-10-17, same session): authoring + admission audit → 44 approved / 6 held

- **R2**: 19 draws (14 gap + 5 held), DataDesigner `answers_r2_19` (prompt v2 = base + guard clause: absence≠contradiction, no authority declaration, no assertions beyond records) + :8081 triage `reviews_r2_19`. Original 5 failed outputs preserved in `held_outputs_preserved.jsonl`.
- **R3**: 4 targeted re-draws (17977, 78794, 22396, 26947), prompt v3 adds verbatim-citation clause + canonical-label clause. Fixed 22396's hybrid label; did NOT stop the parametric imports (17977, 78794) — stable at temp 0.
- **Manual admission audit** (full re-read of every deck; :8081 aid only — it produced 2 useful flags and several false positives, no false-negative rescue):
  - **13 new admits**: 1227, 631, 62962, 84549, 6193, 67038, 30847, 35092, 19964-G1 (R2) + 47079 (R2, **re-keyed N→S**, documented: Model column with four row labels; the NEI gold required an external NSC-class judgment; sibling 22395 "six models" C consistent) + 74223, 88810 (R2) + 22396 (R3).
  - **6 terminal holds**: **49011** KEY_CONFLICT ("in Paddington, London" attaches to the DEATH date under standard bio syntax → NEI, but birth-attachment reading → S/publisher gold; PM to re-key or replace), **80246** (C vs N; "played seasons" = university-years binding never stated; underdetermined), **65919** (2/2: built⇒planned subsumption; underdetermined question; no further cycles per batch3 discipline), **17977** (3/3: stable hallucination of a "Temporal range: Early Cretaceous, 123–96 Ma" record not in the packet — [10] is the page header), **78794** (2/2: fabricated "United Kingdom" co-origin; record [1] is "[[France|France]]" only; verdict S and core citations correct), **26947** (3 draws: verdict instability on the underdetermined WWII/Soviet focus distinction; key N stands).
- **C5 clarification**: C5's selected NEI is 26947 (internal version conflict + omissions) — the first-pass "no not-established case" was an overstatement; the true gap is *missing-link* NEI ("formerly X" where X never appears), which does not exist in the pool. Approved-44 currently contains **zero C5 NEIs** (26947 held) → reported gap, not forced. Per-example version relations in COVERAGE_50.md §6.
- **Shared-evidence groups** (`shared_evidence_groups.jsonl`, reconstructed from pool group_keys — an earlier draft contained two errors: 22396 is the Poul Lange page, not Bodnarchuk; 73152 is not in the pool at all): GRP-flip 1227/1228 (1228 = batch3-38 member AND set2 reserve), GRP-mirror-Vukovi 84549/67038, GRP-mirror-USBridge 6193/30847, GRP-table-USP 47079/22395 (**cross-set**: 22395 is in the set2 trained 50). Rule: all members same side of any train/eval split; all training-side.
- **Excluded 2 (683, 90104) remain excluded, not re-adjudicated** — per instruction.
- **Approved composition (44)**: C1 2S/3C/1N, C2 2S/3C/2N, C3 3S/4C, C4 4S/4C, C5 3S/4C, C6 3S/3C/2N, EXTRA 1S; labels 18S/21C/5N.
- **8011 author failure modes (profile material)**: (1) parametric import of page content not in the packet (stable at temp 0, defeats explicit verbatim-citation directives); (2) hybrid verdict labels on NEI-with-partial-support packets ("Not fully supported", "Contradicted / Not established (mixed)") — fixed by the explicit canonical-label clause; (3) subsumption inferences (built⇒planned; different documented topic ⇒ focus contradicted).
- Files: `final50_reference_key.jsonl` (44 content_approved / 6 content_held + admission_round + notes), `content_candidates_r2_r3.jsonl` (19 rows: raw answer/reasoning/review + decision), `held_outputs_preserved.jsonl`, `answer_seed_r2_19/r3_4.jsonl`, `answer_config_r2/r3.json`, `review_seed_r2_19/r3_4.jsonl`, `review_config_r2/r3.json`, `datadesigner_runs/answers_r2_19|answers_r3_4|reviews_r2_19|reviews_r3_4b/`, COVERAGE_50.md §6-8.

## Round 2.5 (2026-10-17, same session): 47079 re-key doc, 44-roster, TRL inspection

- **47079 re-key (N→S) fully documented** in `REKEY_47079_20261017.md`: exact claim + all 19 records + conjunct-by-conjunct establishment independent of the generated answer. Key records: [3] column header literally "Model", four row labels [4][6][8][10], [16] "Total Internal/External Raw capacity" header, [5] 13PB (first row), [9][11] 332PB (last two rows). The NEI gold required an external NSC-taxonomy judgment (controller vs model) not in the packet. Sibling 22395 ("six models", C, set2 trained) is consistent under the literal reading (6 ≠ 4 and ≠ 3).
- **44-roster built** with dedup identities: `approved44_roster.jsonl` + `approved44_roster_manifest.json`. roster_source: inherited_batch3_38 ×31 / newly_admitted_r2_r3 ×13. Identity fields: roster_id (batch3:<packet_id>), packet_id (global dedup key across public harvests), input/answer/reasoning sha256, pool_source_line_sha256, group_ids. 44 = branch TOTAL, not additive to primary harvest.
- **Data-integrity defects found & fixed in this branch's own files**: (a) my first roster build shadowed c2 (r2_r3 approved rows) with c1 (batch3-38 held rows) for 74223/88810/22396 via `c1.get(p) or c2.get(p)` — rebuilt with explicit partition from the key; (b) 22396's row in content_candidates_r2_r3.jsonl pointed at the R2 (failed) draw instead of the approved R3 draw — raw/reviewed fields now point at answers_r3_4; full byte-exact re-verification passed for all 13 approved rows.
- **TRL inspection of the 44** (maintained `trl_label_check.py`, .venv-training, TRL 1.15.0 / transformers 5.19.0 — same versions as prior receipts): status PASS, 0 errors. Membership 44==44 exact; preservation 44/44 byte-exact + decoded-span match; masking clean per record (completion-only, prompt -100, thinking scaffold + answer supervised at pinned boundary); key-leak scan 0/44 (decisive_basis, key labels, canonical gold labels, gold fields); no truncation path (max_length=None, packing=False in prep AND pilot runner), range 308–1,537 tokens, largest FEVEROUS-62962-G0 1537; full-set stock collator (44 rows) label rows preserved + -100 pad. **Tokens: 30,972 total / 13,987 supervised / 16,985 masked.** Receipt: `TRL_APPROVED44_LABEL_CHECK_20261017.json`; report: `INSPECTION_44_20261017.md`.
- **No training, primary roster unchanged.** Remaining PM gates: 49011 re-key/replace, the 6 holds, eventual combination/dedup against the primary harvest.

## Round 2.6 (2026-10-17, same session): harvest receipt finalized; token decomposition corrected

- **Reporting correction applied**: comparison population is the inherited 31 (not set2's 40). User's proposed 9,043 for the 13 was a cross-recipe artifact (21,929 production − 30,972 user-only). Root cause found: the production pilot recipe (`run_batch3_pilot.py:451-455`) prepends the answer_config system prompt (63 tokens/row, fully masked); the maintained check script (user+assistant only) omits it. 44 × 63 = 2,772.
- **Inherited prep unchanged — hash-confirmed, not assumed**: all 31 `training_payload_sha256` (canonical `json.dumps({input_ids,labels}, separators, sort_keys=True)` — the batch3 receipt's definition, recovered by candidate matching on SCIFACT-123) bit-identical to `TRL_BATCH3_LABEL_CHECK_20261017.json`; source sha d3c269c9 unchanged.
- **Final token decomposition (production recipe)**: 31 → 21,929/7,773; 13 → 11,815/6,214; 44 → **33,744 total / 13,987 supervised** / 19,757 masked. Supervised is recipe-invariant (system prompt is masked).
- **Files**: `TRL_APPROVED44_PROD_PREP_20261017.json` (production receipt, per-row, collator full-set True), `HARVEST_RECEIPT_20261017.json` (sha-anchored final receipt: roster 44 = 31+13, 13-new table, 6 holds, re-key, prep, groups, boundaries), INSPECTION_44_20261017.md comparison section corrected.
- **Harvest status: FINALIZED.** Integration and training explicitly a separate PM decision. packet_id = cross-harvest dedup key; group_ids carry page-level co-membership.

## Session ID & where the work is saved (find-me-later map)

- **Session ID: `01a14a91-b03c-7460-9afa-4171277d6ab0`** (pi seat, jett-8011 / qwen3.8-27b-fp8)
- Session transcript: `/home/user/.pi/agent/sessions/--data-agentic_trading--/2026-10-17T15-53-44-252Z_01a14a91-b03c-7460-9afa-4171277d6ab0.jsonl`
- **Git:** commit `f8897dfe3` on `origin/master` (pushed 2026-10-17) — "Evidence-judgment harvest: set2 registration + batch3 50-branch finalized (44 approved / 6 held)", 94 files.

**Where each artifact lives (all under /data/agentic_trading unless noted):**

| What | Path |
|---|---|
| **The 44-row harvest roster** (this branch's deliverable) | `training_data/derived/evidence_judgment_batch3_20261017/approved44_roster.jsonl` (+ `approved44_roster_manifest.json`) |
| **Harvest receipt** (sha-anchored index of everything) | `training_data/derived/evidence_judgment_batch3_20261017/HARVEST_RECEIPT_20261017.json` |
| Full 50 (44 approved + 6 holds, with reasons) | `training_data/derived/evidence_judgment_batch3_20261017/final50_reference_key.jsonl` + `final50_source_packets.jsonl` |
| Re-key 47079 N→S justification | `training_data/derived/evidence_judgment_batch3_20261017/REKEY_47079_20261017.md` |
| TRL receipts (production 33,744/13,987 + user-only inspection) | `training_data/derived/evidence_judgment_batch3_20261017/TRL_APPROVED44_PROD_PREP_20261017.json` (+ `INSPECTION_44_20261017.md`) |
| Raw R2/R3 authoring + reviewer outputs | `training_data/derived/evidence_judgment_batch3_20261017/datadesigner_runs/{answers,reviews}_r2_19, answers_r3_4, reviews_r3_4, reviews_r3_4b/` |
| Shared-evidence groups (boundary rule) | `training_data/derived/evidence_judgment_batch3_20261017/shared_evidence_groups.jsonl` |
| Set2 50-record working dir | `training_data/derived/public_evidence_set2_20261017/` |
| **Set2 canonical lake** (13 files, LIVE) | `/data/parquet/public_evidence_set2_20261017/` (outside the repo) |
| Eval freeze (6 packets, kept out of training) | `training_data/derived/public_evidence_eval_freeze_20261017/` |
| Ledger entry | `docs/data_pools/POOL_LEDGER.yaml` |
| Seat-analysis report (parallel process diagnosis) | `training/public_evidence_mixed_pilot_20261017/SEAT_ANALYSIS_20261017.md` (commit e1458e8e6) |
