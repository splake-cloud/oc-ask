# Form-T fresh public-data holdout — FROZEN (2026-10-21)

**Deliverable:** a frozen fresh **public-data** holdout for the Form-T three-state task
(E / AN / NE), SQuAD 2.0 + ClaimVer, source-disjoint from the 175-packet train pool.
**NOT** an activity-log incident holdout — that separate set is still outstanding.

## Pipeline (all verify-run deposited)
60 authored (34 NE/13 E/13 AN) → **59** (dropped FT3-SQ-0013-NE Manchester CWC: context
"did not progress past the group stage" = explicit contrary + compound prop) → tightened
disjoint screen **0 hits** vs 488 existing (ID/exact/8-shingle) → blind re-key
(author / 3.6 / :8012) → **49 keep / 10 reject** (author ≠ :8012) → split by source-text
group (matched records together) → **frozen final = 24** (14 NE/7 E/3 AN), dev = 25
(12 NE/6 E/7 AN). Transcripts: `fresh-eval-step1.log`, `fresh-eval-screen.log`,
`fresh-eval-freeze.log` (F1–F6 PASS).

## Two blocking leak repairs from external review (both fixed + verified)
1. **State-bearing packet IDs** (`…-NE/-E/-AN`) + `provenance.pair_type` leaked state into
   model-facing text → opaque randomized join-IDs; state-revealing provenance moved to a
   private `id_map.json`.
2. **Header state-cue**: every SQuAD NE used an "…and related topics" neutral title while E
   controls used the real article title → the header alone predicted state. Fix: **identical
   generic header `## Form-T packet` on all packets, no title/ID in the input**; join-IDs
   independently randomized (32 state-blocks when sorted by ID vs 3 if state-blocked).
   New STEP1 checks V10a/b/c (header identical + ID not state-blocked).

## Re-key rule applied (handoff §4.2)
author's state ≠ :8012 (authoritative) state → **reject**, no auto-reinstatement. 10
rejected: 7 clear author-errors (both re-keyers agreed) + **3 borderline** (3.6 agreed with
the author, :8012 the stricter read) — flagged, NOT auto-reinstated; PM chose to freeze on
the 49 (reinstate later = re-freeze): FT3-jmzfb (Irrisarri NE/E/NE), FT3-h2wm9 (Georgetown
sign AN/NE/AN), FT3-zugky (Yahoo!-Bing AN/NE/AN).

## Files
`training_data/derived/formt_eval_fresh_20261021/` — `final_{packets,keys,id_map}` (frozen
24), `dev_{packets,keys,id_map}` (25), `FREEZE_MANIFEST.md` (sha256 of all six),
`rekey_comparison.jsonl` (three-way, 59), `rekey_{survivors,rejects}.json`, `packets.jsonl`
+ `answer_keys.jsonl` + `id_map.json` (full 59 pre-split), `exclusion_set.json` (disjoint
boundary), scripts (`draw_and_build`, `reauthor_squad`, `repair_opaque`,
`repair_generic_header`, `screen_eval`, `make_rekey_batches`, `collect_rekey`,
`compare_rekey`, `split_freeze`, `verify_freeze`).

## Lessons
- A "label-free" check that only greps for field tokens misses **structural** state cues
  (ID suffixes, title conventions). Check that header text + exposed IDs cannot *predict*
  state (V10), not just that no token is present.
- `:8012` server was alive (200) despite the agent card's stale "server stopped" note —
  verify seat liveness from host vantage before assuming a fallback.
- Neutral titles for NE packets are an intentional anti-leak design (real wiki_title stays
  private in id_map); not a defect.
