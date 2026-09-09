# 2026-09-09 — ES Auction Profile Phase 5 (Auction Geometry) — D1 closed with E-v5-2

Phase 5 builds the geometry layer on the ratified Phase-4 substrate (384-file
battery). Pipeline: `profile → geometry → node naming → studies`. Motto:
"measure the shape first; name the shape second; test its behavior third."

## Current state (as of ~05:00Z)
- **spec_v5.md FROZEN + 2 errata, committed** (`bd31081c` spec, `1e827e9f` E-v5-1,
  `c48497fb` E-v5-2). 1078 lines. §0 design-change rule; §3 S1–S9 frozen
  algorithms; §4 exact schemas (29/26/16→17 cols); §5 Chunks 1–6; §6 fixture
  oracles F-a…F-j; §7 X1–X9 cross-checks; §8 A1–A10.
- **D1 `geometry_core_v1.py` COMMITTED** (`6551898f` + E-v5-2 fix `94ab6871`).
  Stdlib-only pure core, `compute_geometry(bin4, volume, k)`, 17-column
  candidate table (col 17 `va_guard_fired`).
- **D2 `build_profile_geometry_v1.py` (qwen-coder) — EXISTS, UNVERIFIED**:
  session aborted ~3.5h in; 774 lines, compiles, import-clean (pandas/pyarrow/
  geometry_core_v1/stdlib); a 04:26 build ran (1536×29 geometry, 385 manifest
  inputs) but is stale (pre-E-v5-2 D1) and no PM verify-run exists on the
  final file.
- **D3 `check_profile_geometry_v1.py` (qwen38-collab) — stage-1 valid,
  full-mode VOID**: fixture stage 8×PASS + G7 (verify/d3_v1_fixtures.
  20260909T023304Z.txt). The full-mode smoke is VOID as canonical evidence
  (ran against D2's in-progress artifact; checker file modified post-smoke).
- **Stopped per operator**: "commit D1 then stop and wait for PM direction."

## The big one: E-v5-2 (operator ruling + PM discovery, both 2026-09-09)
D1's original Cand A clamped the VA at [L_k, H_k] → 12/384 rows (6 twin
pairs) were 1 tick narrower than Phase-4's VA. Operator ruled (Candidate A
only): the pooled S2 walk advances **exactly as Phase 4** — unconditional
pair advancement, unchanged single stop, outside-support volume 0, **no
clamp**; reported bounds may reach [L_k−k, H_k+k] (k=1: [lo−1, hi+1] = the
ratified Phase-4 E1 bound); LVN complement over [L_k,H_k] only (no synthetic
outside cells); Part A/B/C stay bounded.

**PM discovery that forced the guard**: the literal Phase-4 loop is
**non-terminating** on heads with `up == 0 and dn == 0` and all remaining
volume left of the span (tie→UP advances the empty side forever; the 2-cell
left window never moves). Proven on committed Phase-4 code:
`va_expand([0,3],[3,4])` hangs (timeout-killed). The spec_v4 "loop always
halts" proof is false in general — it only held on the battery. **Frozen
stall guard**: at every loop head before side selection,
`up==0 and dn==0 and Σ_{j>upper} V(j)==0 and 10·cum<7·total` ⇒ break, span
as-is. Provably a strict no-op on every pure-terminating execution; bounds
all reported bounds to [L_k−k, H_k+k] exactly (2-cell overshoot
unreachable). Gate: guard firing on the battery = MAJOR.

**Verification (PM, all via verify-run, study verify/ dir)**:
- `ev5-2-oracle-fixture-and-battery.*.txt` — PM's own independent
  reimplementation: F-i (v=[3,4,0,0,0,4] → VA[−1,5] steps 3 ties 1, no
  guard) PASS; F-j (v=[3,0,0,4,0,0,0] → guard fires, span[3,3] steps 0
  ties 0) PASS; **384/384 Cand A k=1 == Phase-4 summary VA; guard fires 0**.
- `d1-ev5-2-selftest.*.txt` — D1 self-test F-a…F-j all PASS.
- PM battery on D1's actual `compute_geometry`: **384/384, guard 0**.
- `d1-ev5-2-import-audit.*.txt` — imports [sys], zero float literals.

## Rules & decisions banked this session
- Errata E-v5-1 (F-e `ties 1`→`0`; D1 delegate BLOCKED with proof; PM
  re-traced; frozen algorithm authoritative; only the fixture pin changed).
- Contamination guard: Phase-5 inputs = profile files + registry ONLY.
- Parallel authoring: D3 must not inspect D2 source while building G2–G7/G9
  expected-value predicates (spec-only); static audits separate from the
  mathematical oracle. D3 canonical run waits for D2 commit.
- KASA5 = pi seat (qwen3.8-27b-fp8) per operator — same model family as the
  semantic lane; mitigations = full SEMANTIC KASA RULES + D3 independent
  predicates on a separate card.
- verify-run usage: args are NOT shell-parsed — pass the command as
  separate argv words (`verify-run label python3 script.py --flag`), quoted
  string form fails with 127.

## Open / next (operator drives dispatch)
1. D2: PM verify-run on final file (canonical rebuild + schema + double-build
   + /tmp read-scope) → commit. (Current D2 output is stale — pre-E-v5-2 D1.)
2. D3: G6 bound update for E-v5-2 (A-exception [L_k−k,H_k+k] + guard
   assertion) via EDIT mission → fresh canonical full run (PM) → all gates
   PASS + all tampers observed-FAIL.
3. KASA5 (pi seat): S1–S9 matrix, per-claim independent re-derivation, ≥1
   hand trace per claim, structural-independence record.
4. Part D freeze record + Phase 5 closure receipt.

## Key paths
- Study root: `/data/agentic_trading/studies/es_auction_profile/`
- Spec: `specs/spec_v5.md` (E-v5-2 at §0/§3.9/§4.3/§6/Chunk-6-G6)
- Blueprint (ruled): `specs/blueprint_v5_profile_geometry.md`
- D1: `scripts/geometry_core_v1.py` | D2: `scripts/build_profile_geometry_v1.py`
  (uncommitted) | D3: `scripts/check_profile_geometry_v1.py` (uncommitted)
- Phase-4 summary (X9 identity source):
  `outputs/profile_summaries_v1/summary_v1.parquet`
- Phase-4 VA reference impl: `scripts/va_expand_v1.py`
- Profile files: `outputs/profiles_v1/profiles/<profile_id>.parquet`
  (columns: profile_id, price_bin [DOLLARS], volume, volume_fraction;
  **bin4 = round(price_bin × 4)** — the file has NO bin4 column)
