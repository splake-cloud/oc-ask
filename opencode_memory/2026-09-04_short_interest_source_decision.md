# 2026-09-04 — Short-interest source decision (FINRA vs Nasdaq) — BLOCKED on PM decision

Follow-on to the COT backfill thread. Investigating why `short_interest` is 0 rows and
which source to use. **System going down for fan install — resume from here.**

## State: BLOCKED on a PM decision (a) vs (b). Nothing built.

## What was established (verified, not guessed)

1. **No FINRA login exists on this box, and there was never a prior FINRA acquisition.**
   - `.env.secrets` = only `OPENAI_API_KEY` + `MASSIVE_API_KEY`; `.env.stack` = generator/coder endpoints only.
   - Broad sweep (api_key|token|password|login|secret) across non-venv config, filtered to data vendors → 0 FINRA hits. `find -iname "*finra*"` → nothing.
   - Only vendor creds present: ORATS (hardcoded token in `scripts/orats_intraday_ingest.py`), Massive, OpenAI.
   - `short_interest_raw.parquet` = **0 rows**; lineage `fetched_at 2026-09-04T15:21, row_count 0` (fetcher ran today, got nothing). No short-interest data anywhere else; no git commit / session card about a FINRA pull.

2. **Spec never expected a login.** build_spec §2.4 (line 181): *"Source: FINRA (public). CSV."* So there was never login info to store — the premise "login should be on the box" is off.

3. **Why it's 0 rows now:** the fetcher's URLs are dead. FINRA reorganized — old
   `finra.org/finra-data/.../short-volume` pages 404; `data.finra.org`/cloudfront don't resolve;
   old public S3 short-volume feed gone. Current FINRA data hub funnels downloads through a
   **login-gated gateway** — only data link on the hub is `ews.finra.org/auth/logon → gateway.finra.org/app/data`.

4. **Nasdaq equivalence** (answer to "is nasdaq equivalent?"):
   - **Schema: yes** (from knowledge, not a live pull — Nasdaq page is bot-walled 301→node→403 from this box). Carries ticker, issuer, settlement date, short interest (shares), ADV, days to cover; extras float + % short. Missing `previous_short_interest` = derive from prior period.
   - **Coverage: NO** — Nasdaq-listed only (Global + Capital Market). Excludes NYSE, CBOE, OTC. On the overlapping universe the VALUE is identical (FINRA sources it from the exchange), but a big share of large caps (JPM, BofA, Exxon, Pfizer, UHC) are NYSE-listed and would be silently absent.

5. **Option (c) — union of public exchange feeds — is NOT viable** (user initially chose it; I verified and reversed):
   - NYSE/ICE does **not** publish a public short-interest feed (ICE market-data page has none).
   - Nasdaq bot-walled from this box; CBOE data CDN 403; FINRA old S3 gone.
   - ⇒ No no-login all-exchange source exists. FINRA is the only comprehensive source. A "Nasdaq+CBOE" union would silently omit NYSE-listed names = a coverage defect.

## The decision (ask PM on resume)
- **(a) FINRA account** — free FINRA data-center login; spec's intended all-exchange source. PM provides creds → I wire fetcher to the gateway (creds in `.env.secrets`, never committed).
- **(b) Nasdaq-only** — no login, but `short_interest` scope becomes "Nasdaq-listed only"; document the coverage caveat in `data_catalog.yaml` / catalog_freshness so it isn't mistaken for the all-exchange view. Viable only if the positioning layer's equity scope is Nasdaq-centric.

## Files / state (unchanged, no build done)
- `/data/agentic_trading/scripts/fetch_short_interest.py` — still points at dead FINRA URLs (would need rewrite for either (a) or (b)).
- `/data/parquet/institutional_positioning/short_interest_raw.parquet` — 0 rows.
- `warehouse/models/short_interest.py` — `context.fetchdf` fix already applied (from COT backfill thread); model itself is fine, just no source data. Plan still fails all-or-nothing on this 0-row source (prod env not committed).
- COT backfill itself is COMPLETE (see `2026-09-04_cot_backfill_to_current.md`).

## On resume
1. Ask PM: (a) FINRA account or (b) Nasdaq-only?
2. If (a): get creds, rewrite `fetch_short_interest.py` to gateway, run, re-materialize, re-export.
3. If (b): find the live Nasdaq short-interest endpoint (needs a browser / non-bot-walled vantage to confirm — could not from this box), rewrite fetcher to Nasdaq, add coverage caveat to catalog, run.
4. Either way: once raw pool is non-empty, re-run `sqlmesh plan --auto-apply` to commit the prod env (currently inconsistent because short_interest is 0-row) + `scripts/export_warehouse_models.py`.
