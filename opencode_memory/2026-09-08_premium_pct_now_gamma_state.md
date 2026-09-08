# 2026-09-08 — premium_pct_now gamma-state display + gold-cell alert

## What was built
Extended `scripts/premium_pct_now.py` (the `premium_pct_now` bash alias) with an opt-in
gamma display + gold-cell alert. New flags: `--gamma` and `--gamma-body <strike>`.
Without `--gamma`, output is byte-identical to before (445 insertions / 0 deletions vs HEAD —
purely additive, so the last good working file is intact at HEAD; revert = `git checkout -- scripts/premium_pct_now.py`).
**NOT committed** (PM hold: do not commit until it works end-to-end).

## Key facts settled (with sources)
- **Runner contract (PM-confirmed):** client writes `<id>.req` (JSON body) to
  `studies/0dte_fly/staging/gamma_nodes/requests/`, polls `.../responses/<id>.json`.
  Bodies: `{}`, `{count:N}`, `{from,to}`, `{date,count}`, `{date,all}`, `{at}`; modifiers
  `no_prev`, `allow_empty`; statuses `ok/empty/error/skipped`; `files` = flat basenames in
  staging root (2 files/slice: `_exposures.json` + `_positions.json`). Hard cap 200 slices, RTH-only,
  ~120-day retention.
- **Data schema (verified from real `SPX_20260908_152000Z_exposures.json`):** top-level dict
  `data/prev/prev2/prev3`; `data` = COMPLETE strike book (one row/strike, fields
  `ticker_id/timestamp/strike/participant/gamma/charm/vanna/delta`). `gamma` = SIGNED dealer value
  (float, no nulls, NO OI field, positive = dealer-long). Only `data` from `_exposures.json` is read.
- **Regime = 0DTE_ONLY (PM-confirmed 3 ways):** feed captured `min_dte=0&max_dte=0` on all 7,434
  records / 184 days, relative per observation date. TRAP: the parquet `expiry` column is NOT a
  reliable label (71% log `expiry="all"` even though the DTE filter was on) — never read regime from
  `expiry`. The staged file/response carry no DTE field, so the display hard-codes `0DTE_ONLY` from
  this authoritative fact.
- **Math = canonical `keeper_candidate_rule`** (RAG): body γ>0 ×3, MAX(rank)≤3 (not min),
  min(body/top1)≥0.50, min positive-book share ≥5%, STRONG if min body γ≥5,000.
- **No live active-fly interface exists** (only historical `fly_trades`/`fly_paths`) → body source =
  `EXPLICIT` (override) or `NOW_NEAREST25` (default, the NOW-block body); `GOLD CELL: NOT EVALUATED`
  (touch/damage inputs unavailable; no interface invented).

## Output shape
`GAMMA — on-demand` block appended after the per-checkpoint blocks: header (Slice/age/regime/Body/source),
`Current:` (body gamma + size band, rank, top1/top2 nodes, Q1/Q2, positive + gross share, spot, spot→body,
snapshot ts), `History:` (up to 3 captures incl. current, with gaps), `GAMMA STATE: size·dominance·trend·persistence`,
`GOLD CELL: NOT EVALUATED`. Statuses `GAMMA EMPTY / ERROR / SKIPPED / PENDING-UNAVAILABLE / SCHEMA ERROR`.

## Design decisions (flagged to PM)
1. Regime `0DTE_ONLY` (was `NOT STATED` before PM confirmed).
2. `spot` = the NOW-block live SPX (labeled), not a snapshot-time `spx_1min` join (out of scope).
3. `GAMMA STATE` = `size · dominance · trend · persistence`; size + persistence are the ratified
   tokens; dominance (DOMINANT/SECONDARY/MINOR) + trend (BUILDING/FADING/FLAT) are clearly-labeled
   descriptive qualifiers extending the PM's illustrative example.

## Verification (all 8 points PASS)
Transcript: `verify/gamma_integration.20260908T173316Z.txt`. Runner was BLOCKED by the backfill,
so a verification seam `GAMMA_REQ_ID=<id>` pins the request id to consume a pre-seeded
`responses/<id>.json` through the normal poll path (verification-only; no effect on normal runs).
1. no `--gamma` → 0 GAMMA lines, no req file written, byte-identical non-gamma output.
2. `--gamma` consumes the matching response (GAMMA_REQ_ID).
3. `ok/empty/error/skipped` + pending/timeout all print correctly.
4. Independent recompute of body 7700 @15:20Z from raw rows matches: g_b=19471.2178, top1 7700,
   top2 7650/3562.9568, rank 1, Q1 1.0000, Q2 5.4649, S+ 0.5830, Sgross 0.3355.
5. Gamma prints with `GOLD CELL: NOT EVALUATED`.
6. Future-dated slice excluded (code trusts the file's internal `timestamp`, not response metadata).
7. R_worst = max(rank) across all three captures.
8. No entry threshold/action changed (RULES / classify_zone untouched; 0-deletion diff).

**Catch at the gate:** the first delegate pass computed G_min/R_worst/Q1_min/S+_min +
GAMMA_CONFIRMED/STRONG over only the 2 *history* captures (current snapshot excluded) and showed 2
History rows. Re-dispatched a corrective EDIT → now uses all 3 captures and shows 3 rows / 2 gaps.
Also: a delegate's returned `git diff` mis-rendered a doubled path (`STAGING_ROOT/"gamma_nodes"/"requests"`)
and broken indentation — the ACTUAL file was correct (verified by import + grep); the returned diff was
not trusted, the file was re-read.

## End-to-end (runner live) — DONE
Runner came online. Real `--gamma` (no seam) works: writes `<id>.req`, runner claims it, stages 3 fresh
slices, writes response. **Runner end-to-end latency ~33s** (.req 17:34:46 → response 17:35:19), so the
original 30s `GAMMA_POLL_TIMEOUT` was too tight → bumped to **60s** (tuning constant, not a spec value).
Live run completed in 34s, printed full block. Independent recompute of the real 17:30Z file matched
(g_b 21453.44, top2 7690/5011.29, rank 1, Q1 1.00, Q2 4.28, S+ 53%, gross 34%).

## TZ display fix (PM red flag) — DONE, verified
PM caught: dashboard showed `Slice: 17:30 ET` for a `17:30Z` source. **Diagnosis: display-only, NOT
internal.** Parse (line 437 `fromisoformat(ts.replace("Z","+00:00"))`), eligibility compare (line 440
`slice_dt <= decision_time_utc`), and age (line 460 `decision_time_utc - current_dt`) ALL already used
aware-UTC instants (correct). Defect: `strftime("%H:%M")` was called on the aware-UTC datetime (formats
in UTC) but labeled "ET". Fix (3 lines): `.astimezone(ET)` before the Slice + History strftimes, plus a
`source:`/`ET:` diagnostic. Verified: summer 17:30Z→13:30 ET (UTC-4), winter 17:30Z→12:30 ET (UTC-5);
17:30Z fixture now prints `Slice: 13:30 ET`, `source: 2026-09-08T17:30:00Z`, `ET: 2026-09-08T13:30:00-04:00`,
History `13:10/13:20/13:30`; age from aware-UTC instant (14-15m); gamma values UNCHANGED. Transcript
`verify/gamma_tz_fix.*.txt`. Still 447 insertions / 0 deletions vs HEAD (purely additive).

## Open / next
- Commit only after PM says it works (currently 447 insertions uncommitted on `scripts/premium_pct_now.py`;
  revert = `git checkout -- scripts/premium_pct_now.py`).
- The `GAMMA STATE` descriptive qualifiers (dominance/trend) are PM-flagged for possible trimming.
