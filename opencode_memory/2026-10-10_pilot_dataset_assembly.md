
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
