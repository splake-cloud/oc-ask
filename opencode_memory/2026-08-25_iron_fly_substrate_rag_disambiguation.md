# Iron fly substrate was wrong (body/wings); RAG "fly" poison disambiguated

**Date:** 2026-08-25 · **Seat:** oc-ask · **Topic:** iron fly baseline backtest foundation + RAG disambiguation

## What happened

PM started the first iron fly backtest on this box (Mon 11:30 entry, Fri 15:59 exit,
DTE 4). Asked to verify the existing `iron_fly_weekly_substrate` before building on it.

**The substrate is structurally wrong for the spec:**
- Spec: body = nearest **5**-pt strike to spot; wings = **±100** per wing (200 total); 4 legs.
- Substrate (`warehouse/models/iron_fly_weekly_substrate.sql:82-84`): body =
  `FLOOR((spot+12.5)/25.0)*25.0` (nearest **25**); wings = `body ± 25` (50 total).
- Verified in the materialized table: 25/25 spreads `lower_gap=upper_gap=25.0`.
- The 4-leg pivot, algebra, Mon 11:30 / Fri 1559 / DTE 4 are all correct — **only the
  strike construction is wrong.** Raw pool `spx_intraday_strikes` is fine (full 5-pt grid
  verified: 499 strikes, all 5-pt multiples on 2022-06-06).

**Why it went wrong — the RAG served butterfly facts as iron-fly facts.** The first
iron fly is the only 4-leg structure on the box; every RAG "fly" card describes the
3-strike **0DTE put-butterfly** study. A builder grounding on "fly wing width" /
"body strike" retrieves:
- `spx_cash_centered_option_strikes` — "body = nearest **25**-point grid" (byte-identical
  to the substrate's body error) ← the direct ancestor.
- `spx_20w_fly_wing_spacing` — "this per-wing definition is the **only canonical house
  interpretation**."
- `spx_long_put_fly_debit` — 1/-2/1 3-strike algebra, `max profit = wing_width - entry_debit`.
- `checkpoint_calendar_early_close` — 15:55 exit; `spx_0dte_fly_canonical_sources` — 0DTE scope.

Market convention (PM): "100W" = ±100 per wing = 200 total (parity argument: if W were
total, per-wing = W/2, which breaks on odd-5 widths since SPX strikes are 5-pt). The
RAG card's "house interpretation" framing was the trap — it's a study convention, not a
market rule, and it was applied to a structure it doesn't describe.

## The fix (committed `f45b0c28`, `scripts/rag_verifier/build_contracts.py`)

1. New `data_contracts` card `iron_fly_vs_fly_disambiguation` — binding term
   disambiguation + the iron-fly spec + "the first substrate is WRONG on body/wings."
2. One-line SCOPE prefix on the 7 butterfly cards so the scoping travels with every
   retrieval even when the disambiguator loses the rerank.
3. `spx_20w_fly_wing_spacing`: "only canonical house interpretation" → "convention for
   this study" (removed the universality claim).

Seeded both roots (`data_contracts` 85→86, full+small live). Verified (verify-run):
`rag-disambig-ironfly-finds=1`, `rag-disambig-poisontop-carries-scope=1`. The poison card
`spx_20w` now serves with its SCOPE prefix in the served text.

## Review trail (both independent, both APPROVE)

- **qwen-coder (EXPLORE):** syntax PASS; all butterfly claims verified w/ file:line; iron-fly
  claims UNVERIFIED-by-design (PM-given, no model source); flagged 2 missing negations.
- **claude-opus-4-7 (headless, `claude_wrapper.py`):** approved semantics, NO operational
  errors in the seeding steps; **MAJOR finding** — one disambiguation card is under-powered
  for *butterfly-worded* queries (it leads with "IRON FLY", which hurts its rerank against
  5+ butterfly cards; the failure that actually happened was butterfly-worded). That finding
  is the reason for the SCOPE prefixes. Also confirmed in code: `payload.triggers` do NOT
  affect the `/search` chat/seat lane (`bm25_text = title+text`, `kb_store.py:129`); triggers
  only fire on the keyed gate path (`grounding.py`).

## Key facts / paths

- Iron fly spec (authoritative, PM): body=nearest 5 to spot@Mon1130; wings=±100 (200 total);
  legs=long put wing / short put body / short call body / long call wing; entry Mon 11:30;
  exit Fri 15:59; DTE 4.
- Wrong substrate: `warehouse/models/iron_fly_weekly_substrate.sql` (do NOT use as ref).
- Pool (good): `/data/parquet/spx_intraday_strikes/**/*.parquet`, `hive_partitioning=false,
  union_by_name=true`, `expiryTod='pm'`, `snapShotEstTime` HHMM int, quotes zero-not-NULL.
- RAG builder: `scripts/rag_verifier/build_contracts.py` (data_contracts is a CURATED well,
  `CONTRACTS` dict, NOT a CARDS list — RAG.md §0.5 step 3 is stale on this).
- RAG reseed: `refresh_planner.py scan-stage --groups data_contracts` → `seed-pending --root
  all` → `status --root all`. No service restart needed (existing well).
- `claude_wrapper.py` is at repo ROOT (sweep moved it from `scripts/`); CLI:
  `python3 claude_wrapper.py --system ... --user ... --model claude-opus-4-7`.

## Open / next

- **Rebuild the iron fly substrate** to the correct spec (body nearest-5, wings ±100).
  Scope agreed: this is a substrate-only exercise — do NOT embed the backtest/PnL into it.
  The RAG fix is defense-in-depth; the rebuild TASK SPEC must still carry the 4 structure
  params explicitly + "do not re-derive body/wings from the RAG" (the card protects future
  queries, the task spec protects this rebuild).
- Catalog `iv_percentile_daily` floor was separately fixed (9359→8652, commit in this
  session) — that was a real pre-existing drift, unrelated to iron fly.
- `scripts/archived` / `.external` cleanup (REPO_HYGIENE_PLAN.md) is parked — its dead/orphan
  classifier is untrusted (it listed live cron `refresh_fly_panel.sh` for deletion).
