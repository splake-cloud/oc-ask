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
### 2026-09-09 (late): canonical D3 full-mode run — PASS
:8012 three-round review loop (NO-GO F1/F2 → NO-GO F5 → GO) caught 3 real full-mode
defects (fixture-scale assumptions: T1 pid, trough-walk first-cell, G5 `twin` column)
+ my F1b. Canonical run then caught a 4th the review loop missed: D2 manifest
`n_rows` keys non-conformant to spec §4.4 (short keys pinned at line 438; D2 wrote
file-stem keys; my own §C checker had hard-coded D2's keys — ledger item 6). D2 fixed
(1e8969fd, parquets byte-identical), run 2: **RESULT (full): PASS exit 0**
(`d3v2-canonical-full.20260909T134625Z.txt`), run 1 FAIL transcript kept as provenance
(`...133931Z.txt`). All UNPROVEN-UNTIL-RUN items cleared. Part D (geometry + node
naming) verified end-to-end. Next: KASA5 semantic lane (S1–S9 matrix) if dispatched.
### 2026-09-09 (latest): KASA5 complete — S1–S9 all CONFIRMED
receipts/kasa5_adjudication.md. KASA re-derivation (no production imports;
dict-pooling, runs-as-triples, integer-exact) matched every cell: 1536 +
139576 + 34018 rows + 10/10 fixtures. 1 MINOR: §3.9 Cand-C prose two-readable;
§6 pins fix it (maximal runs of the qualifying set); build == pins. Process
incident K6: I reported a "PASS" before reading the transcript (it was exit 1,
harness key-name bug cand vs candidate) — corrected same turn, false-claim
recorded in the receipt ledger; future rule: no verdict before reading the
deposited transcript. Part D closed semantically; Part E freeze awaits GO.
### 2026-09-09 — PHASE 5 CLOSED
Operator ratified the frozen study interface and closed Phase 5.
specs/study_interface_v1.md (ratified, frozen v1): hash-pinned substrate,
keys/row-order, NULL + E-v5-2 bound semantics, arm semantics (canonical
HVN/LVN NONE; A literature arm, B/C sensitivity), primary representation =
continuous Part-A geometry, success states YES/NO/CONDITIONAL/
REDUNDANT-WITH-CONTINUOUS-GEOMETRY, change-control (new quantity/threshold =
new version + new adjudication), per-study checklist. Closure receipt:
receipts/phase5_closure_receipt.md. Next stage (new dispatch): candidate-node
behavior studies on the frozen substrate.
### 2026-09-09 — PHASE 6 RULED: frozen spec_v6 written (pi, handoff-incoming session)
Operator rulings on blueprint_v6 D1–D8, with three amendments, encoded in the
FROZEN `studies/es_auction_profile/specs/spec_v6_pit_market_context.md`
(blueprint marked superseded). Amendments: (1) v1 fields TRIMMED to a closed
32-column list (IDENTITY 5 / COORDINATE STATE 3 / NATIVE 8 / FRONT 4 / PRIOR 7
/ RELATIVE 3 / ROLL STATE 2); exact-bar source admitted (session aggregates
from the substrate's exact interval bars); **no discretionary regime labels in
v1** (high_volume_day/wide_range_day/trend_day/volatile = thresholds that
belong later). (2) Join criterion corrected to the INVERSE pair: every profile
exactly one context match (join key = profile asof session); every context row
≥1 profile match; no context row outside the declared 20-session population;
native/front twins map to the SAME context row (coordinate column selection,
no duplicated context records). (3) Minimal semantic-claim set S1–S7 (context
timestamp / PIT admissibility / session aggregation / prior-session resolution
= immediately preceding complete eligible session, never calendar D−1 /
coordinate mapping / future-deletion invariance f(I_≤t)=f(I_full) / no
outcomes), with **S2/S6/S7 highest-severity KASA claims**.
Grounded facts verified before spec writing: 384 profiles, 20 distinct asof
sessions 2026-04-13→2026-05-08 (10–24 profiles/session; 76 are prior_eth
anchored); 21 substrate partitions all single-contract ESM6, partition D spans
D−1 18:00→D 17:00 ET; C*=ESM6 unambiguous all 20 asofs (front_delta=0 is a
data fact, transform stays general); roll ESM6→ESU6 triggers 2026-06-15
(out-of-window ⇒ live_leg_required=false all rows); **2026-04-13 has no prior
session in the substrate ⇒ its prev_* (7) + RELATIVE (3) block is NULL +
manifest refusal code by construction**. 2026-05-11 partition is post-window
(truncation-invariance later-cut only, not a context row).
Next: D1 context builder → qwen-coder; D2 gates G0–G6 (G2 truncation
invariance decisive; G6 = the 4-way join contract) → qwen38-collab; KASA S1–S7
(pi, ≥1 hand-traced date); :8012 review before canonical run; canonical run;
Phase-6 freeze record.

### 2026-09-09 — PHASE 6 RULES GIVEN → FROZEN SPEC v6
Operator ruled D1–D8 (recommendations stand, three amendments). Frozen spec:
`studies/es_auction_profile/specs/spec_v6_pit_market_context.md` (committed in
/data/agentic_trading); blueprint_v6 status line updated to "RULED".
Amendments: (1) v1 field list is a CLOSED 32-column set — exact-bar source
admitted; NO discretionary regime labels (high_volume_day/wide_range_day/
trend_day/volatile = thresholds that belong later, new version). (2) Join
acceptance = four-part: every profile exactly one context match (join key =
profile asof session); every context row ≥1 profile; no row outside the 20
declared sessions (2026-04-13→05-08); native/front twins share one row,
select coordinate columns. (3) Phase 6 built around semantic claims
S1–S7 (timestamp / PIT admissibility / session aggregation / prior =
immediately preceding complete eligible session, never calendar D−1 /
coordinate mapping / future-deletion invariance f(I≤t)=f(I_full) / no
outcomes); **S2/S6/S7 = highest-severity KASA claims (BLOCKER)**.
Grounded facts pinned in spec §2: 20 asof sessions (10–24 profiles each,
384 total; 76 prior_eth anchors); substrate 21 partitions all ESM6;
C*=ESM6, is_ambiguous=False all 20; ESM6→ESU6 roll triggers 2026-06-15
(out of window); 2026-04-13 prev_* block = NULL + manifest refusal (no
prior session in substrate — expected). Refusal reason codes live in the
manifest refusal block (field list has no reason columns). Next: D1 builder
→ qwen-coder; D2 gates (G0–G6 incl. truncation invariance, 3 cut points) →
qwen38-collab; KASA pi; :8012 review before canonical run.

### 2026-09-09 — PHASE 6 SPEC REV 2 (four operator corrections, commit 42839bfa)
Operator named 4 defects in frozen spec v6 — all masked by the all-ESM6
identity window (C*=source, front≡native, roll out of window ⇒ every
coordinate/roll code path numerically invisible on the real battery):
(1) "exact-bar source admitted" was never in the input contract:
vap_atomic is minute × price-bin × volume ⇒ no first/last trade ⇒ no
exact session open/close. FIX: bar source = `/data/parquet/es_1min_live/`
Databento per-contract 1-min bars, 21 pinned files (trade_date=D file
holds the full atomic session D−1 18:00→D 16:59, 1380 bars), sha256 in
manifest (live sqlmesh pool). Closed per-field ownership: BAR SOURCE →
O/H/L/C + prev O/H/L/C; VAP → total_volume/trade_count/n_distinct_
price_bins. Grounded: bar-sum volume == VAP totals EXACTLY (04-13
1,470,840; 04-14 1,241,952); ESM6 window coverage incl. prior session
04-10 present; instrument_id 42140864. (2) S6 too weak: atomic-only
truncation invariance passes while builder reads future
front_assignment rows (05-11+) or the ESM6→ESU6 roll row (trigger
2026-06-15, status data_gap — a post-asof fact inside a declared
input). FIX: S6 = Context_D(I_≤T_D) = Context_D(I_full) with as-of
reconstruction per time-bearing input (VAP rows / exact bars / front
assignment / roll state / session universe), 3 truncation points, ≥2
test dates. (3) D3 needed Phase-2 mapping semantics: P_front =
Map_P2(P_source → C*(T), T) (chained settled roll offsets, spec_v2 §3);
front_delta = mapping RESULT, not a Phase-6 roll calc; S5 needs a
synthetic NONZERO fixture (oracle 5000/A/B/+12.25 → 5012.25 +
unresolved/live-leg refusal) — S5 is unprovable on the identity
battery. (4) source_instrument_id must be the generation-aware
instrument ID (UINTEGER 42140864 = ESM6@2026, consistent across
es_1min_live + roll_table), never the reusable symbol "ESM6".
Side-effect correction: 2026-04-13 prev block — prior session IS in the
bar source ⇒ prev OHLC + prev_range_ticks FILLED; only prev_volume +
volume_ratio_prev = NULL (NO_VAP_PRIOR_SESSION). Spec now rev 2
(42839bfa); gates renumbered G0–G7 + G-consistency. Next dispatch
unchanged: D1 builder → qwen-coder.

### 2026-09-09 — PHASE 6 D1 BUILT + VERIFIED (48ffca7d); D2 dispatched
Operator confirmed the field-by-field distinction (prior existence/prices ≠
VAP availability) and added the binding 04-13 oracle → spec rev 3
(139c0d72). GO for the dispatch chain given.
D1 (qwen-coder, 1 bounce): scripts/build_context_v1.py. PM-verified
(verify-run d1r2-build/d1r2-checks): full build sha256
0d6e5dc1a123ad6ca75dec7ca3af3fb99d02ff8c25ca5ef22d2c9ed228edb3dc,
deterministic; self-test leaves canonical byte-identical (bounce fixed a
self-test clobber of the canonical 20-row output with its 2-row build);
36-check PM battery (verify/check_context_v1.py) ALL PASS — schema,
04-13 oracle cell-for-cell (prev OHLC populated 6858/6888/6846.25/6863.75,
range 167, gap −335, ratio 3.8622754…; prev_volume + volume_ratio_prev
NULL w/ NO_VAP_PRIOR_SESSION only), bar↔VAP anchors exact. Bounce also
fixed 6-decimal rounding of ratios (full DOUBLE now). Manifest = 43 inputs
+ sha256 (21 bars, FA, RT, 20 VAP). D2 (G0–G7 + G-consistency battery,
incl. per-input future-deletion w/ 3 truncation points and synthetic
Map_P2 fixtures) dispatched to qwen38-collab (:8011).

### 2026-09-09 — PHASE 6 D1+D2 COMPLETE, :8012 REVIEW LOOP CLOSED (pre-canonical)
Full dispatch arc executed under the operator's GO chain:
- D1 builder (qwen-coder, 2 bounces) → 48ffca7d, then bounce-2 provenance
  fixes (total_volume VAP-sourced + in-build bar==VAP invariant; instrument
  IDs resolved from bar file + roll-table cross-validation) —
  value-identical, canonical sha256 0d6e5dc1… unchanged. Final: 48e595c5.
- D2 gate battery (qwen38-collab) → scripts/check_context_v1.py: G0–G7 +
  G-consistency, sandbox injection of the builder's own code, per-input
  future-deletion (5 inputs × 2 dates + 3 truncation points), synthetic
  Map_P2 fixtures (5012.25 + live-leg refusal), G7 join 384/384, tamper
  suite. 10/10 gates, 3/3 tampers, exit 0.
- :8012 review (qwen38-reviewer, read-only) → **NO-GO** with 2 blocking
  MAJORs the per-chunk verification could not see (all dormant on the
  identity window — the loop working as designed): M1 unconditional
  `front_mapping_status="resolved"` overwrite killed the AMBIGUOUS_FRONT
  refusal branch; M2 live_leg_required filter inverted (selected settled
  rolls; fixed to the closed window test trigger ≤ asof < settlement +
  synthetic self-test); M3 vacuous ID cross-validation bracket (fixed to
  latest-generation row + asserts). All fixes PM-verified in source first,
  then value-identical (hash unchanged), commits 48e595c5/a2e68f22
  (G4 synthetic world + m3/m4/m7a minors). Banked for the freeze record:
  m2 (registry gate-side, not manifest-pinned), m5 (prev_volume float64 =
  D5 NULL consequence), m6 (trade_count isna relaxation, sha-pinned),
  m7b (manifest path cosmetics). Reviewer's caveat: S6 coverage = G2+G3b
  JOINTLY (G2 alone has no FA/roll teeth). Review outcome appended to
  review/context_v1_canonical_run_review_package.md (00782598).
- :8012 diff-only re-review (qwen38-reviewer) → **GO** (canonical run
  authorized): both remediation commits contain exactly the five fixes
  (M1/M2/M3 + G4-for-M3 + m3/m4/m7a), no unrelated drift, each changed
  branch proven dormant on the frozen window (value-identity holds).
- Formal canonical verification run (verify/contextv1-canonical-full):
  G0–G7 + G-consistency 10/10, tampers 3/3, PM acceptance battery 32/32,
  determinism double build byte-identical in-transcript. Canonical
  artifact sha256: context_v1.parquet
  0d6e5dc1a123ad6ca75dec7ca3af3fb99d02ff8c25ca5ef22d2c9ed228edb3dc,
  manifest.json aeed74cf2a7225bedb539bb9d99a2420342425e77454ac4259766a389ee9e9b6.
- **KASA6 (pi seat, structurally independent — no production imports)
  → PASS.** Primary trace 2026-04-13 hand-computed from raw inputs:
  OHLC 6780.0/6928.25/6767.0/6927.5 (n=1380), range 645 ticks, VAP
  vol=1470840/trades=458999/bins=646 (bar-sum == VAP), prior 04-10
  OHLC 6858/6888/6846.25/6863.75, prev_range 167, gap −335,
  range_ratio 645/167=3.8622754…, VAP(04-10) absent ⇒ prev_volume +
  volume_ratio_prev NULL (NO_VAP_PRIOR_SESSION) — the oracle reproduced
  independently; exactly-2 refusal block. S5 non-identity: KASA
  arithmetic 5000+12.25=5012.25 + live-leg refusal (T=05-03 in
  [05-01,05-06) ⇒ REFUSE, no partial offset). S2/S6/S7 highest-severity,
  all CONFIRMED non-vacuously (106 later FA rows + 2026-06-15 roll row
  present in inputs, excluded; S6 bit-identical at 3 cuts). 32-cell
  re-derivation: 0 mismatches. Ledger 0 BLOCKER / 0 MAJOR / 0 MINOR.
  Harness verify/pm_kasa6_rederive.py; receipt
  receipts/kasa6_adjudication.md; transcript
  verify/kasa6-adjudication.20260909T184227Z.txt.
- **PHASE 6 CLOSED / PASS WITH CLEAN KASA ADJUDICATION (operator, 2026-09-09).**
  Freeze record: receipts/phase6_freeze_record.md (pinned artifact set:
  context_v1.parquet 0d6e5dc1… 20×32; manifest aeed74cf…; spec rev 3
  62ea5bf8…; builder 0320d804…; checker de72832a…; PM battery
  f3346948…; KASA harness 8e9ef2d9…). Operator points carried verbatim
  in substance: KASA6 S1–S7 all CONFIRMED; ledger 0/0/0; primary trace
  04-13 (BAR-present / prior-VAP-absent selective-refusal oracle);
  S2/S6/S7 non-vacuously confirmed highest-severity; S6 = G2+G3b
  jointly; S5 real window = identity (non-identity +12.25 & live-leg
  refusal fixture-adjudicated); M1/M2/M3 = closed-finding provenance
  (NOT current limitations); banked m2/m5/m6/m7b (none blocks);
  antecedent-state layer only (no outcomes, no regimes); v1 scope =
  17:00 ET session-close PIT context for NEXT-SESSION studies —
  same-session/intraday studies require a NEW context version.
- Study state: Phases 0–6 ALL CLOSED.
- **Study A (HVN attraction, next-session form) scoped — operator ratified
  the first-study choice 2026-09-09.** Blueprint
  specs/blueprint_v7_study_a_hvn_attraction.md + build spec
  specs/spec_v7_study_a_hvn_attraction.md (DRAFT, same shape as spec_v4/v5,
  committed). Key scoped facts: primary definition = asof session's own
  complete_trade_date profile (1 per session); 20/20 asof pairs have a
  complete next-session ESM6 bar file (05-08→05-11 complete in the bar
  source; the 05-11 partial is VAP-only); arm-A k=1 internal share 90/192
  (47%) — internal-band rule D2 is load-bearing; ~1,950 primary event rows.
  Chunks: D1+D3 qwen38-collab (:8011 semantic core + independent gates),
  D2 qwen-coder (:8081 assembly), KASA = pi seat (App. A: S1/S3/S6 highest
  severity; K3 = real weekend pair 04-17→04-20 hand trace from the raw bar
  file). Fixtures F-a..F-f hand-derived + mechanically checked (caught a
  defective F-f pin + an F-e band that would have been 'internal' — both
  fixed pre-commit). **PENDING: operator ratification of D1–D8** (next
  session rule / internal handling / native coordinate / bin4+hi4_excl /
  MAE-MFE / primary definition+T1-T4 protocol / context_v1-only
  conditioning / study-package deliverable) — spec freezes on ratification,
  then dispatch D1→D2→D3 → KASA7 (kasa7_adjudication.md) → study receipt.

### Study A: D1–D8 ruled, spec v7 FROZEN (2026-09-09)
- Operator rulings: **D1 AMENDED** (immediate next pool session `E′=min{s:E>s}`;
  refuse the pair if absent/incomplete; **never forward skip**; never calendar),
  D2 ratified, D3 ratified (native canonical; front twin never a second
  observation), **D4 ratified with pin** (0-based touch bar index = bar-start
  offset; first outcome bar ⇒ 0/0), **D5 AMENDED** (miss = minimum bar-range-
  to-band interval distance over full session — directional shortcut went
  negative on gap-over: F-b now carries a gap-over bar, miss 2 not −6),
  D6 ratified, **D7 ratified with clarification** (context_v1 = entire
  admissible source; T1–T4 use only protocol-declared context variables
  gap_ticks/range_ratio_prev; no post-outcome feature selection), D8 ratified
  (study artifact package only).
- Fixtures F-a..F-f re-pinned to amended rules; all reproduce mechanically
  (verified in-session). In-window facts unchanged: 20/20 admitted, identity
  window, 47% A/k=1 internal.
- Spec: `specs/spec_v7_study_a_hvn_attraction.md` (FROZEN); blueprint v7
  ruling table updated. Commit `ca09d8ba`.
- Next: dispatch D1 (qwen38-collab :8011, `scripts/study_a_core_v1.py` Chunks
  1–3) → D2 (qwen-coder :8081, build) → D3 (qwen38-collab, gates+analysis) →
  KASA7 (pi seat) → study receipt.

### Study A: FULL CHAIN EXECUTED & CLOSED (2026-09-09, operator GO)
- **D1** study_a_core_v1.py (qwen38-collab): e2e9a7cd → 95ee29dc (E-2) →
  d7fe701e (wording). Errata E-1/E-2 raised by D1, PM-adjudicated
  (d1ba5369).
- **D2** build_study_a_v1.py (qwen-coder): 8325340f (E-4 values) → 8405826e
  (pin refused probe file) → 3cdaee0c (X7 root overrides). **E-4: in-window
  census corrected by direct measurement** — 04-29 bar file has 1379 rows
  (missing 2026-04-28 19:21 ET) ⇒ asof 04-28 REFUSED (the D1 amendment
  working as designed); 19/20 admitted; 509 rows; arm A k=1 internal 15/19
  (90/192 was a wrong-population whole-pool figure).
- **D3** check_study_a_v1.py (qwen38-collab, 9594d74c): G0–G9 all PASS,
  tampers 5/5 observed-FAIL, import audit PASS. D3 caught a PM envelope
  slip (T3 median A k1 168 vs printed 170) via its cross-assert — refused,
  not weakened.
- **X7** /tmp-copy build: byte-identical event sha (28 manifest diffs =
  path strings only).
- **KASA7** (pi seat, pm_kasa7_adjudicate.py): 10/10 CONFIRMED, 0 BLOCKER /
  0 MAJOR. Hand traces: weekend 04-17→04-20 (internal cells) + 04-13→04-14
  (touched C k1 r2: bar 120, mae 17, mfe 13; non-touch misses 136/43).
- **VERDICT: NO** per frozen §3.8 (C q1<q4 all 4 scales; B un-evaluable —
  q4 internal-depleted; two-arm YES config not established). Small-N
  honest posture; C signal recorded in verdict_evidence.
- **Banked MINORs pending operator ruling:** M1 decision-rule gap
  (one-arm-evaluable case unmapped — recommend explicit mapping next
  protocol version), M2 K8 1-char extraction delta, M3 PM envelope slip
  (process note), M4 stale §10 attestation line.
- Artifacts (sha256 in receipts/study_a_hvn_attraction_receipt.md): spec
  39e5efe6…, core 17261a06…, build b24fd6c6…, check 33f13d6a…, harness
  bcd07d35…, event 8758a1a0…, manifest c75183a4…, analysis 53338452….
- Commits: ca09d8ba → … → 66aa9464 (closure receipt). Next studies
  (B first-encounter, C LVN traversal…) are operator-driven.

### Closure ruling (operator, 2026-09-09) — Study A FINAL; next = Study B
- **Study A = CLOSED / NO** (confirmed; not reopened). M1–M4 BANKED as
  provenance; E-1…E-4 BANK CLOSED (no retrofit).
- **New forward-looking protocol rule (binding, protocol v2 onward):**
  multi-arm decision rule + structurally unevaluable required arm ⇒
  **INDETERMINATE**, unless the remaining evaluable evidence
  independently satisfies a separately pre-declared terminal rule.
  Transcribed in study_interface_v1.md addendum §7 (frozen body
  untouched). Does NOT apply retroactively to Study A.
- **Subsidiary finding preserved separately:** Arm C q1<q4 at all four
  scales incl. gap splits — evidence for follow-up; must not determine
  any later study's thresholds/arms/outcome/queue position.
- **Queue: A (CLOSED/NO) → B (first encounter, NEXT) → C (LVN traversal).**
  B before C by pre-registration order (sequence must not be
  outcome-responsive). B = behavioral decomposition behind A: A = does
  structure get REACHED; B = what happens AT the first encounter
  (idea.md: APPROACH → TOUCH → REJECT/ACCEPT/TRAVERSE).
- Commits: 66aa9464 (closure receipt) → 606448c8 (ruling + addendum).
- Study A artifact set pinned in receipts/study_a_hvn_attraction_receipt.md.
