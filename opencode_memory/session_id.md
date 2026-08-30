# session_id

<!-- IV backfill 2021 build spec (studies/iv_weekly_substrate/specs/build_spec_iv_backfill_2021.md): verified + ratified C1–C8. Caught: KA_M2_06 false-alarm (252d window 2024-01-04→2025-01-06 untouched by backfill), §8/§3 drift, DEFECT 1 (Gate-2 KASA must use throwaway backfilled-M1 carrier db, not state DB — virtual layer is old-window 3,192 rows), DEFECT 2 (post_write_verify.py single-model-scoped → C8 --expect-changed + --row-baseline idempotency, carrier verify/<gate3_dir>/00_m1_row_baseline.parquet). Coder assignment: qwen-coder 3.6, transpositional. Dev env: backfill_dev. -->
<!-- Session: ses_fb2971704ffe6vW6QXvT2S47sj | Spec ratified (DRAFT, uncommitted); Gate-1 envelope staged -->

<!-- Iron Fly L2-B: root-caused broken path retrieval (entry_spread_key encodes row snapshot time, not trade identity); patched to logical-trade-tuple query; 352/352 n_rows + MFE/MDD + frozen acquisition numerators (241/213/197) reproduced exactly; V1-V11 PASS; sensitivity non-monotonicity reconciled (genuine, center is local min); Friday-mark "drift" was probe artifact (0/352), frozen friday_pnl = Monday 15:59 (L2-A mislabel documented). -->
<!-- Session: ses_fb620e9cbffeOUlOUGmzuLhAJb | Patched studies/iron_fly_weekly/scripts/iron_fly_l2b_threshold_stability.py (uncommitted) -->

<!-- IV backfill-to-2021: Gate-1 (C1-C8) APPLIED + verified; coder3.8 review PASS-WITH-FIXES (carrier naming); Gate-2 carrier KASA ALL PASS. Gate-3 STAGING packet built + M2 discrepancy ADJUDICATED (STOP -> PASS): M2 = version FIELD 2902785128 carried over / INDIRECT_NON_BREAKING (spec's 3013756842/FORWARD_ONLY was wrong - to_version() not version FIELD); data NOT stale (FULL model re-runs over new M1, full-window backfill). Prod sha256 invariant. D9 upper bound closed. Next = PM-token-gated prod write. -->
<!-- Session: ses_fb1efa917ffeSS6g82KUZw5POe (C8 ratification + Gate-3 staging) / dispatch ses_fb1df2f48ffeyc7zPI1klEnI1t (G1) / review ses_fb1ca0919ffetWV3NgMqLpC3cN (3.8) / carrier ses_fb046f9b5ffe5T3e2qUkqIHRU2 (G2) | cards 2026-08-29_iv_backfill_2021_gate1_applied.md + 2026-08-30_iv_backfill_gate3_staging_m2_adjudicated.md -->

<!-- IV weekly substrate: M2 iv_weekly_percentile prod write + closeout (build complete); then reorg of IV into studies/iv_weekly_substrate/ (own study folder, verify/navigation.md entry point) + RAG placement card made retrievable (study_infra re-indexed, --force, small GPU / full CPU). -->
<!-- Session: ses_fb51abd23ffe7bijhfK4JmlYRE | Committed+pushed 65203b0f, 5eef452b, 81201293, d0375a72 on iron-fly-economic-baseline -->

<!-- Iron Fly V0 gate LOCAL path fix: blueprint ordering, NameError, standalone V2 guard, e2e tests. -->
<!-- Session: ses_fb5c7f0f3ffe8xmHANRNWzgvIX | Committed: 18f0054e on iron-fly-economic-baseline -->
