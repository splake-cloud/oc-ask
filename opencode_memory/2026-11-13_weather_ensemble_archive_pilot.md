# Weather ensemble archive — pilot built and proven (2026-11-13)

Pi session `01a1d2b5-e58e-7507-99ad-e7d13d3dd30d` (pi-web, agentic_trading).
Work is on disk under `/data/agentic_trading/weather_archive/`; committed
(market_data `23955984c` pilot, `1fcc1de00` winter/unit-fix).

## Day-2 update (2026-11-13 evening → 11-14 03:00 UTC)

- **W2025-26 backfill**: GEFS DONE (1,198,080 msgs ok, 0 failed, 200 GB, 13.6 h)
  + acceptance validation ALL PASS (19,328 member-init pairs 100% finite,
  identity + identical-date revisions). ECMWF/AIFS-ENS ~92% (init 2026-03-09),
  493 per-file S3 SlowDown failures recorded on holiday dates — idempotent
  retry pass after DONE.
- **O layer via CDS**: cdsapi 0.7.7 works but `/tasks/` polling is dead (new
  datastores client; monitor via `client.get_jobs()`). Winter-window ERA5
  delivered; then 6-hourly (604× = 151d×4, 24 MB, job d3fd46a3) →
  `slices/wx_obs.parquet`, builder verified cell-by-cell vs raw netCDF.
  12Z UTC = US morning cold minimum (noon-only HDD biased HIGH).
- **K/F unit bug found & fixed (wxlib-1.1)**: derive computed HDD as
  `65F − (K−273.15)` — Celsius vs Fahrenheit base, 3 sites; ERA5 cross-check
  exposed it (conus HDD 51.99 vs 9.6 correct, 2025-11-01; the 51.99 reproduces
  the Celsius formula exactly). Raw zarr stores always correct (Kelvin).
  Derived DD/ens/revision tables + study W/C panels rebuild at the
  post-backfill joint re-derive (derive-mid-write caused an earlier zero-fill;
  re-derive must wait for BOTH stores closed, then assert no all-zero winter
  runs).
- **4-season gap batch launched**: GEFS + ECMWF inits 2026-04-01→2026-10-15
  (units wx-gap2026-{gefs,ecmwf}; GEFS started, ECMWF queued behind winter
  backfill on the per-source flock). Gives one continuous four-season year
  Nov 2025→Oct 2026, both models, no code changes.
- **History reach measured**: same-code floor = GEFS FV3 2021-11 (verified
  pgrb2ap5 on bucket; 2022+ = zero new code, ~35-40 GB/winter); old eras
  2017-2020 exist but are different grids (2017-2018 1° verified from files,
  2019-2021.10 0.25°) needing per-era decoders (~200-230 GB downsampled);
  ERA5 truth 1940→ now via the proven CDS path (~60 MB/winter CONUS).
- **ng_weather_eval**: P panel done; harness smoke PASS both models; v1.1 eval
  spec still not on disk as a frozen file (pre-registration gap).


## What exists

- `DESIGN.md` — architecture + pilot results (§10); `README.md` — runbook.
- `wxlib.py` — unsigned S3 (ContentLength-verified GETs, NoSuchKey fast-fail),
  GEFS `.idx` / ECMWF `.index` parsers, eccodes decode (FileReader API),
  per-point box subset (regular + reduced-Gaussian), write-once zarr FieldStore,
  append-only parquet manifest (29 identity columns), atomic index cache.
- `acquire_gefs.py` / `acquire_ecmwf.py` — era-probing, inventory-discovering,
  idempotent acquirers (`--days/--members/--steps/--limit` filters).
- `derive_products.py` — t2m_region_daily, dd_region_daily (65°F base,
  per-member nonlinear DD before averaging), ens_daily (incl. hdd/cdd gap vs
  DD-of-member-mean), revision_daily (consecutive-run warmer/colder/flat),
  missingness. Weights: `config/weights_v1.json` (PROVISIONAL equal, cos-lat
  area-weighted) — every product carries weights_version.
- `asof.py` — availability gating on s3_last_modified (no later-run
  substitution); `readiness_report.py` → `readiness_report.md`.

## Proven (pilot 2026-10-16→29, T2M, na_gas box)

- GEFS era B: 116,480/116,480 msgs (56 inits × 32 members × 65 leads),
  19.37 GB, store (56,32,65,11473,1) 100% filled, all validated.
- ECMWF aifs-ens 0p25: 87,108/87,108 msgs (28 inits × 51 members × 61 leads),
  34.32 GB, store (28,51,65,45441,1). Source publishes 0–360h only (S3-verified);
  4 empty store leads = source inventory.
- Idempotent reruns: 0 GB re-transferred, 0 unresolved failures (one transient
  GEFS fetch recovered on rerun).
- 10/10 independent byte-range re-fetches sha256-match source.
- As-of check: 2026-10-20T12:00Z → 00z available (pub 06:04:58Z), 12z excluded.
- Manual revision check (conus 2026-10-25): GEFS 00z→12z mean +0.15°F
  (24 warmer/4 colder), ECMWF −0.17°F (4 warmer/39 colder).

## Gotchas banked (hit live, fixed)

1. Background nohup jobs die when the agent systemd slice is reaped → long
   runs need `systemd-run --user --unit=...` (killed both pilots at 03:58).
2. Concurrent index-cache writes raced (shared tmp name) → unique tmp per
   thread + os.replace, parse-before-cache. Caused 306 spurious failures in
   one ECMWF run; 4,995 duplicate manifest rows remain (append-only parts
   preserved; dedup on read; idempotence set-based, unaffected).
3. Truncated S3 GETs (no error) → ContentLength verification in s3_get.
4. eccodes python 2.x: use `FileReader` + `msg.data`/`msg.get`, not
   `codes_grib_new_from_file`; `latitudes`/`longitudes` are per-point arrays;
   ECMWF aifs-ens members identified by `number` field (all expver 0001),
   control = cf file; ECMWF index name = grib key with `.grib2`→`.index`;
   GEFS geavg T2M = `TMP:2 m above ground` (member files use `TMP:surface`).
5. ECMWF lons come back −180..180, GEFS 0..360 — normalized to 0..360 East in
   subset_reduced.

## Next (not started)

- Commit-and-push when PM asks (weather_archive/ is self-contained; idx_cache
  6.2 GB is disposable — exclude from git).
- Backfill per DESIGN.md §9 (era boundary 2017→2026 not yet pinned;
  ECMWF 0p4-beta era from 2023-01-18).
- Demand weights v2 (wire a gas-demand dataset; weights_v1 is provisional).
- Observations for verification (design: verification-only, not in archive).
