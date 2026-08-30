# 2026-08-30 — Iron Fly L2-D1 body-convergence anatomy: exclusion-accounting defect fixed + re-run

Resumed in-flight from session `ses_faf5ffcc8ffeeq4yisMKvcSql0` (prior agent had diagnosed the
defect but the fixed script had never been re-run — on-disk outputs predated the final edit).

## The defect (root cause, confirmed)
`studies/iron_fly_weekly/scripts/iron_fly_l2d1_body_convergence_anatomy.py` — the L2-D1 body
convergence anatomy of the frozen `moving_toward_body` selector. The parent set (Gate 2, verified
vs frozen build) is 119 (primary) + 75 (robustness) = **194**, but the pre-fix run reported
eligible = 126 (C1–C4 = 103+7+11+5) and Gate 4 "excluded = 0". **68 parent trades were silently
dropped** — a selection bias that PM ruling #1 forbade ("letting the anatomy's extra data
requirements silently redefine the frozen population").

Mechanism: the parent rule uses `_spx_eff` (carry-back-1) — matching the frozen build — but
`classify_geometry` requires **raw** `spx[t-10]` + all of `spx[t-29..t]` + `spx[t-30]` non-NULL.
A parent trade whose `spx[t-30]` is NULL (but `spx[t-31]` is not) is in the parent set yet
unclassifiable. The pre-fix classify loop appended only when `leaf is not None`, dropping those
trades with no record; Gate 4 counted exclusions only inside `leaf_assignments`, which never
contained them → always reported 0. Gate 3 "passed" circularly (eligible := "the set I classified").

## The fix (delegated qwen-coder, on disk, verified by read-back)
- `classify_geometry` (L381-442) returns a 6-tuple incl. `excluded_reason` (`spx_t10_null` /
  `spx_window_null` / None).
- Main loop (L987-994) records **EVERY** parent trade into `leaf_assignments` with its delta
  (eligible AND excluded) so Gate 4 can count exclusions and measure bias.
- `gate_3_partition_exactness` (L449-464) is now **non-circular**: PASS iff
  `classified + excluded == parent_total`.
- `gate_4_exclusion_report` (L471-499) reports per-pop exclusion counts by reason, exclusion_pct,
  escalation (> `SPX_UNAVAIL_ESCALATION_PCT` = 5.0%), and eligible-vs-excluded mean delta.
- Report gains a **"Selection Bias (Excluded Parent Trades)"** section (L1290-1322) with a caveat
  when excluded mean delta ≠ eligible.

## Re-run result (verify-run deposited)
Transcript: `verify/l2d1_exclusion_fix_rerun_20260830T162030Z.20260830T162030Z.txt` (exit 0).
Arithmetic now reconciles EXACTLY:
- **primary**: 74 eligible + 45 excluded = 119 ✓ (excl: 4 spx_t10_null + 41 spx_window_null)
- **robustness**: 52 eligible + 23 excluded = 75 ✓ (excl: 2 + 21)
- **total**: 126 + 68 = 194 ✓; leaves 59+44+4+3+8+3+3+2 = 126 ✓
- Gate 3 PASS, Gate 4 = REPORT with **ESCALATION** (37.8% / 30.7% > 5%). 6/7 gates PASS (Gate 4
  is a report, not a pass/fail).

### The bias the fix exposes (the whole point)
- **primary**: eligible mean Δ = **4.271**, excluded mean Δ = **1.230** → the dropped 45 trades
  are ~3.5× worse. The convergence effect was inflated by silently discarding the losers.
- **robustness**: eligible 4.632, excluded 4.736 (excluded slightly *higher*) — bias is
  pop-dependent, not uniformly one direction.
- H1 now **FAILS** both pops (C1 not strictly dominant), H2 FAILS (bad_bucket_share 0.667 / 0.50),
  H3 mixed. The leaf numbers the prior agent "would not accept" are now the honest, accounted set.

## Banked conclusion (PM-verbatim, receipt `studies/iron_fly_weekly/receipts/l2d1_body_convergence_anatomy.md`)
**L2-D1 RESULT:** the original moving_toward_body selector remains a real raw
continuation-expectancy signal, but the proposed path-anatomy decomposition is not reliable
enough to explain its mechanism. Reason: 31-row SPX-window eligibility excludes 37.8%/30.7% of
the parent population; exclusion is materially outcome-associated in primary; H1 and H2 fail on
the correctly-accounted eligible subset. Therefore: **no anatomy-derived continuation rule is
adopted; no causal/mechanistic claim about same-side convergence/crossing/reversal; the original
L2-D conclusion is unchanged** (moving_toward_body improves mean continuation P&L but fails the
bankable win-rate standard).

## State
- **CLOSED & committed** `623df92a` "research: close L2-D1 body convergence anatomy" (7 files:
  script, spec, 4 outputs, receipt). Frozen inputs untouched (Gate 7 PASS).
- Receipt mirrors L2-B freeze format: verbatim conclusion up top, defect+fix provenance,
  correctly-accounted partition table, bias numbers, H1/H2/H3 results, verify transcript,
  SHA256 of all 6 artifacts.
- Cosmetic fix (qwen-coder EDIT, verified by read-back + re-run): the report's "Anatomy
  Conclusion" line printed "H3 HOLDS" (was the `pooled_primary` key only); now computed over all
  four h3_results keys → reads "H3 FAILS (1/4 gradients non-decreasing)". Receipt hash table
  updated for the new script + report sha256. Landed as **`1762a96a`** "research: L2-D1 report -
  H3 verdict over all 4 gradients (was pooled_primary only)" (3 files only).

## Concurrency incident (shared worktree, branch `iron-fly-economic-baseline`)
A parallel RAG-harvest seat committed `5b3f642f` (harvester-only) **and pushed it** on top of my
close commit `623df92a` (so `623df92a` is already on origin). My `git commit --amend` for the H3
fix then created a **divergent** local `e5c1657e` (same harvester message + my 3 files) → branch
ahead-1/behind-1. **Must not rewrite pushed `5b3f642f`.** Recovery: `git reset --mixed 5b3f642f`
(worktree untouched — it was a busy shared tree with the other seat's ~81 uncommitted
IV-backfill/RAG files, all ` M`/`??`, nothing staged) → my 3 files became unstaged → committed
them alone as `1762a96a`. Verified: branch ahead 1, `1762a96a` touches only my 3 files, the other
seat's 81 files still present & uncommitted. **Lesson:** on a shared worktree/branch, `--amend`
is unsafe — a concurrent commit can move HEAD off the commit you meant to amend; verify
`git log --oneline -1` is still *your* commit immediately before amending, and prefer a new
commit over amending when another seat is active.
