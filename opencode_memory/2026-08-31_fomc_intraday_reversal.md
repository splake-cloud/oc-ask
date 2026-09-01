# FOMC Intraday Reversal — Session Receipt

**Date:** 2026-08-31
**Session:** `ses_fa817d8caffez66irsz9tJSt5j`
**Status:** Redirected — intraday reversal branch closed, next-day analysis sealed

## What was built

1. **Technical spec v2** (`specs/technical_spec_v2.md`): Corrected event classification (31 holds, 11 hikes, 6 cuts — not all holds), bar semantics, validation framework
2. **Technical briefing v2** (`receipts/technical_briefing_v2.md`): 10 findings with verification, v3 signal frozen
3. **Research incident receipt** (`receipts/research_incident_lookahead_v2.md`): Documents the fatal lookahead bias in Rule 2 v1
4. **Trade ledger v2** (`outputs/trade_ledger_v2.csv`): Corrected real-time running low signal (no edge)
5. **Next-day ledger final v1** (`outputs/next_day_ledger_final_v1.csv`): 44 events, 1 excluded (2025-06-18 missing T+1 data)

## Key findings

### Intraday reversal (closed)
- Rule 2 "Failed New Low" v1 had **fatal lookahead bias**: used completed-window minimum known only at 14:45
- v1 result: N=26, mean +0.36%, win 77%, p=0.005 — **all artifact**
- v2 (real-time running low): N=25, mean +0.17%, win 52%, p=0.22 — **no edge**
- v3 (reclaim of 14:30 bar low): N=16, mean +0.30%, win 56%, p=0.14 — **non-significant**
- **Conclusion: V-shape reversal mental model falsified at executable level**

### Next-day path analysis (sealed)
- 44 events analyzed (1 excluded: 2025-06-18 missing T+1 data)
- No unconditional T+1 or T+2 directional edge found
- T+1 UP count reconciled: 24/44 (55%) — all partitions agree
- Weighted means reconcile: overall -0.068% = init_dir weighted avg = extends/reject weighted avg
- Gap-fill definitions corrected: half_fill=28 (64%) >= full_fill=22 (50%) — nesting satisfied
- Extends vs Rejects: EXT (n=26) mean -0.300% vs REJ (n=18) mean +0.266%, diff -0.566pp, Welch p=0.1022, permutation p=0.1245
- LOO stable: differences range -0.53pp to -0.67pp across leave-outs
- **Not statistically significant** (n=18 rejects is bottleneck), but directionally consistent and economically large

## Open questions
- Extends/reject signal needs ES-level validation with executable entry, target/race stops, execution stress testing
- Cut days (n=6) too small for meaningful analysis
- Additional FOMC events (2026-04-29, 2026-06-17, 2026-07-29) will become available as data arrives
