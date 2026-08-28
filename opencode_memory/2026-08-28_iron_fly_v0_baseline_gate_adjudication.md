# Iron Fly V0 Baseline Gate — Final Build Adjudication

## Verdict: BLUEPRINT REVISION REQUIRED

Adjudicated the coder's build of the V0 audit-bundle + V2-binding blueprint
(`ses_fb782c061ffeF1sA6peGssgvU7`, blueprint in parent `ses_fc08e374bffehsN5D5tHIVj6KU`).

## What works (verified live)
FROZEN path is correct. Gate RC=0, 5/5 PASS, FROZEN_BASELINE_COMPATIBLE.
- `audit/v0_authorization.json`: v0_script_hash == gate sha256 (ea0183b0…),
  study_input_fingerprint == v0_results.csv sha256 (dec5eeda…), baseline_id == manifest.
- `baseline_reference.json`: consistent, both files mode 0444.
- Second gate run aborts on immutability (RC=1).
- 36/36 tests in tests/test_proof_generation.py pass; no other test imports the gate.

## Defects (core objective — LOCAL path — is broken)
1. **Gate `generate_local_baseline()` NameError** — `manifest` referenced at
   scripts/iron_fly_v0_baseline_gate.py:1267 & :1284 but never defined in that
   function's scope (it's a local of `run_gate()`). Coder INTRODUCED this by adding
   the V2 proofs block. Forced LOCAL_BASELINE_REQUIRED in temp dir → guard passed,
   metrics computed, local_baseline.csv written, then `NameError: name 'manifest' is
   not defined`. Unsafe partial success.
2. **Gate never writes v0_authorization.json on LOCAL path** — `run_gate()` calls
   `enforce_proofs()` (line 1077) BEFORE writing the auth file (line 1101). On a
   LOCAL verdict at least one axis proof is required+FAIL and V0_VERDICT is
   required+FAIL (line 1063), so enforce_proofs() SystemExit(1)s first. Forced
   population FAIL → audit/ got only v0_results.csv/v0_summary.txt/proofs.json/
   verification_report.md; NO v0_authorization.json, NO baseline_reference.json.
   → V2's guard (which reads that file) can never be satisfied.
3. **Standalone `iron_fly_v2_local_baseline.py` is UNGUARDED** — the documented V2
   entrypoint (per memory card + style guide) has no auth/verdict/fingerprint check.
   Ran it in a clean temp dir with no auth file → RC=0, generated local_baseline.csv
   + manifest + proofs. The "remove env-var guard, bind V2 to gate" objective is unmet
   for the actual entrypoint.
4. **`__main__` LOCAL branch is dead code** — line 1304 `if verdict==LOCAL:
   generate_local_baseline()` is unreachable because run_gate() aborts first (defect 2).

## Root cause (blueprint, not just coder)
The blueprint's own invariants contradict its objective for the LOCAL path: it orders
"write v0_authorization.json AFTER enforce_proofs()" AND "if any required proof fails,
do NOT create the audit bundle." But a V0-FAIL (LOCAL) verdict legitimately produces
required-FAIL proofs, so the bundle can never be created on exactly the path it's for.
Also the blueprint's "Grounded Current State" misidentified the V2 entrypoint (assumed
only the gate's internal `generate_local_baseline()`, missed the standalone script).

## Required
- Blueprint: resolve the enforce_proofs/bundle-write ordering contradiction for the
  LOCAL verdict; designate the single canonical V2 entrypoint and guard IT.
- Implementation: fix NameError (define manifest in generate_local_baseline or pass
  baseline_id in); move auth-file write before the abort; guard the standalone V2.
- Verification: an end-to-end LOCAL test (force one axis FAIL → assert v0_authorization.json
  written with verdict=LOCAL_BASELINE_REQUIRED → V2 generates baseline) — none exists;
  all 11 TestAuditBundle tests run the FROZEN path only.

## Pre-existing (not this build, secondary)
scripts/iron_fly_v0_regression_tests.py hardcodes `pass: True` for trade_definition,
outcome_construction, race axes (lines ~240-349) — only population + granularity
actually compare. notebooks/baseline_gate_demo.ipynb:74,101 still reference the old
top-level v0_results.csv/v0_summary.txt (moved into audit/).
