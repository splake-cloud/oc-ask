# ECMWF live field stores — locations and freshness reading

Created 2026-11-20 (pi seat 01a1f94c, jett-8013 / qwen3.8-flash-next-nvfp4).
Model-authored; all timestamps below are observed on disk, not inferred.

## Locations

| store | root |
| --- | --- |
| AIFS-ENS live, ECMWF grid `ecmwf_aifs0p25` | `/data/agentic_trading/weather_archive/fields/ecmwf/aifs-ens-live/ecmwf_aifs0p25` |
| IFS-ENS live, grid `ifs0p25` | `/data/agentic_trading/weather_archive/fields/ecmwf/ifs-ens-live/ifs0p25` |
| GEFS live, grid `gefs_0p5` | `/data/agentic_trading/weather_archive/fields/gefs/gefs-live/gefs_0p5` |
| GFS deterministic, Jan-2026 event store (not a live lane) | `/data/agentic_trading/weather_archive/fields/gfs/det-event202601/gfs_0p25` |

AIFS and IFS-ENS are separate roots. NOAA products live under `fields/gefs/` and
`fields/gfs/`, not under a `fields/noaa/` tree: `fields/noaa/` does not exist on this
host (checked 2026-11-20 14:20 UTC, `ls fields/` returns `ecmwf gefs gfs
frozen_registry.txt`). There is no GFS live root here — `gfs_0p25` appears only inside
the Jan-2026 deterministic event store.

Store roots are not listed in `weather_archive/WEATHER_DATA_INVENTORY.md`.

## Freshness reading, 2026-11-20 14:12 UTC (observed)

Both ECMWF lanes are collecting. The lane is NOT stalled.

| lane | newest file on disk | newest poll | last poll that downloaded |
| --- | --- | --- | --- |
| IFS-ENS 0p25 | 2026-11-20 08:56 UTC | 14:07 UTC | 08:07 -> 08:56, ok=3050, 0.98 GB, wall 48.4 min |
| AIFS-ENS 0p25 | 2026-11-20 06:23 UTC | 14:07 UTC | 06:07 -> 06:23, ok=3111, 0.89 GB, wall 15.1 min |

Polls run every 30 min for both products (96 poll logs/day total, 48 per product).
Between landings the polls read `ok=0 fail=0 skip=0 absent=0 transfer=0.00GB` with
`window manifest 18483 rows` — the manifest is already satisfied on disk, so there is
nothing to fetch. `ok=0` is the healthy idle state, not a stall.

Real downloads land roughly every 12 h. Observed spacing: IFS 11-19 20:42 -> 11-20 08:56;
AIFS 11-19 18:43 -> 11-20 06:23. Next due (inferred from that spacing, unproven):
AIFS ~18:07 UTC, IFS ~20:07 UTC, 2026-11-20.

Writes confirmed to land in the roots named above: `find -newermt` window counts give
3050 IFS files in the 11-19 20:00-21:00 hour, 3052 in 11-19 08:00-09:00, and 3111 AIFS
files in the 11-19 18:00-19:00 hour, matching the `ok=` counts in those polls.

## How to check freshness (the log alone cannot tell you)

A healthy store's newest file lags the current time by up to ~12 h, so a bare newest-mtime
probe reads as "stalled" when it is not. Use both:

```bash
# 1. newest file per store
for s in ecmwf/ifs-ens-live/ifs0p25 ecmwf/aifs-ens-live/ecmwf_aifs0p25; do
  find /data/agentic_trading/weather_archive/fields/$s -type f \
    -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort | tail -1
done
# 2. newest poll that actually transferred something
cd /data/agentic_trading/weather_archive/logs
ls -t {ifs,aifs}-ens-POLL-*.log | head -200 | xargs grep -lE 'ok=[1-9]' | head -3
```

Failure signal for a real stall: the ~12 h slot passes and that slot's poll still reports
`ok=0` with a nonzero expected window — i.e. newest landing older than ~24 h.

## Superseded reading

An earlier reading served from the memory index for this filename said the ECMWF stores
were frozen at 2026-11-19 08:59 (IFS) / 07:06 (AIFS), and placed NOAA GFS and GEFS in a
shared root `fields/noaa/gfs-live/gfs0p25`. That file was not present on disk in this
workspace when checked at 2026-11-20 14:12 UTC. Both statements are wrong here: the
freshness figures are two 12-hour cycles out of date (superseded by the table above), and
the NOAA root does not exist (superseded by the NOAA rows above). Cause of the wrong
NOAA path: unverified — no evidence inspected for how it was written.

## Not shown by this check

- Whether upstream ECMWF publishing is on schedule: a poll only sees what the archive
  lists, so `ok=0` cannot distinguish "nothing published yet" from "collector cannot see it".
- Which forecast run/valid times the 3050/3111 files cover — not inspected here, so no
  claim is made about data completeness through any valid time.
