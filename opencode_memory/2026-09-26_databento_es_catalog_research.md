# Databento ES catalog research (2026-09-26)

Task: scope Databento historical backfill of transaction-level ES trade data 2010-06-06 → 2025-05-10.

## Settled facts (sources in report)

- Only CME dataset on Databento: **GLBX.MDP3** (verified via `metadata.list_datasets()`, 29 datasets total).
- Dataset start **2010-06-06T00:00Z**; `trades` schema available from 2010-06-06 (transaction-level, full period).
- **Grain discontinuity 2017-05-21**: MBO / CMBP-1 / CBBO start then (MDP 3.0 MBOFD). Pre-2017 = MDP 2 level-aggregated FIX flat files (max grain MBP-10), no `ts_recv` (= ts_event, F_BAD_TS_RECV set).
- **2015-11-20**: CME nanosecond timestamps begin; before = millisecond resolution.
- Unit prices (historical $/GB, live API 2026-09-26): trades $28, tbbo $28, mbo $1.80, mbp-1 $1.80, mbp-10 $0.50, bbo-1s/1m $18, ohlcv-1s/1m $70, ohlcv-1h/1d $190, definition $1.70, statistics $1.00, status $4.00.
- Costs (trades, ES.FUT parent): 2010-only **$85.27** (68.1M recs); 2021-only **$108.02** (86.3M recs); target window 2010-06-06→2025-05-11 **$1,869.89** (1,493,886,073 recs, 71.71 GB billable); 2010-06-07→2026-09-21 **$1,916.32** (1,658,151,446 recs).
- The PM reference "$1,915 for 2010" = the **full-period frozen quote** (spec v12 §0.3: 1,658,144,461 recs / $1,915.11, quoted 2026-09-20), NOT 2010 alone. 2010 is cheaper than 2021 (fewer trade records).
- "$683 for 2021" UNVERIFIED — no single 2021 ES.FUT schema matches (closest combos ~$674–677: mbo+mbp-1+tbbo, mbp-10+trades+tbbo).
- Databento has **no** MDP3-10MS / TRIP / TRADIES / TICKS products and no 100ms MDP3 schema. "GLBX 100ms MDP3 aggregated" (on-disk naming) is not a Databento product name; aggregated products are only OHLCV bars and MBP/BBO levels.
- VAP substrate = `trades` schema (price+size per trade) — exactly what spec v12 deep pull uses.
- Deep pull status (2026-09-26): manifest 0/196 slices ok, 110 failed, all `402 account_insufficient_funds` — account needs funding before the pull can complete.
- Data end (2026-09-26): 2026-09-26T11:20Z.
- On-disk pilot store `/data/parquet/es_mbo/es_mbo_events_v1.parquet` (hive) actually covers 2026-04-12→2026-05-10 (25 partitions, 262.7M rows), not the 2025-05-11 start recalled in the mission.

## Key URLs

- https://databento.com/catalog/cme/GLBX.MDP3/futures/ES
- https://databento.com/docs/venues-and-datasets/glbx-mdp3
- https://databento.com/docs/schemas-and-data-formats
- https://databento.com/docs/schemas-and-data-formats/trades
- https://databento.com/pricing
- https://databento.com/docs/faqs/usage-pricing-and-data-credits
- https://databento.com/docs/api-reference-historical/basics/metered-pricing

Local: `studies/es_auction_profile/specs/spec_v12_c_replication_deep_history.md` §0.3, `scripts/pull_es_trades_deep_v1.py`, `/data/parquet/es_mbo/es_mbo_events_deep_v1.manifest.json`, `logs/es_mbo_ingest/deep_v1.log`.

## Next items

- Fund the Databento account (or apply $125 credits / subscription) before re-running the deep pull.
- If PM wants front-month-only billing, request via continuous symbology (client 0.78 rejected `ES.FUT.1`/`continuous` — needs API/portal check).
