# Condition-A methodology live run  - 2026-10-21

## Settled

The PM-approved 12-idea condition-A package completed its separate unscored activation pilot, final freeze, and 36 fresh Pi holdout sessions on jett-8011/qwen3.8-27b-fp8. The frozen live methodology corpus was 72 cards, SHA-256 4cce32030e8837eb9801e85d1342844767de0f70474528ea7f44603736064f8a. Four planned sessions (002, 025, 030, 036) were quarantined by the tool/proxy guard, leaving eight assessable ideas and 31 binding rows. Supplemental rerun of 002 was also quarantined for an empty bash command and did not replace the original.

Across 93 clean requirement attempts, a key-listed card was delivered in 33. All 33 were named; selection was not credited in the 60 unserved attempts. Application passed 85/93, spec fidelity 89/93, gap handling 37/93. Seven answer-level quotes attributed to methodology cards were non-verbatim; no nonexistent M/T ID was detected. No binding row passed every axis in all three runs, so no zero-error bound applies. The source frame was content-aware-selected and the clean subset may be biased by quarantine.

## Durable artifacts

- /data/agentic_trading/docs/methodology_condition_a_live_results_2026-10-21.md  - report, quarantine table, limits, own-error record.
- /data/agentic_trading/docs/methodology_condition_a_live_scores_2026-10-21.json  - per-row, per-run axes.
- /data/agentic_trading/docs/methodology_condition_a_live_card_log_2026-10-21.json  - 416 live queries, delivered IDs and hashes.
- /data/agentic_trading/docs/methodology_condition_a_quote_audit_2026-10-21.json  - seven attributed quote mismatches.
- /data/agentic_trading/docs/methodology_condition_a_holdout_freeze_after_pilot.json  - authoritative freeze, SHA-256 0ed0d312a4d035367290925241de8af0b83510751391b6776abfa1b957355bc4.
- /tmp/verify_runs/condition-a-final-artifacts-v2.log  - passing result invariant receipt.
- Published origin/master commit 0e350c003cd725e8952d4b0912c82b6543a49d0c; all nine file blobs verified.

## Next

PM reviews the separated retrieval, application/spec, gap-handling and quote-fidelity findings. Do not turn 33/33 conditional naming into a general selection claim or infer a rule-of-three bound. The original pre-pilot package is preserved in the frozen keybook and candidate manifest.

## 2026-10-22 guard correction

The original guard's four quarantines (002, 025, 030, 036) arose from command-form rules rather than invalid serving conditions. The repaired `scripts/methodology_condition_a_guard_v2.py` (SHA-256 190ebb9730cba3c66824082480a6aa9cb169b77044253ce272aca2a2082605e7) passed 75/75 self-tests, a 20/20 independent command decision table, and the exact 36 planned session rescan: 36 PASS, zero QUARANTINE. The separate supplemental rerun also passed and remains outside the planned denominator. The original 32/36 result stays as the frozen historical report; the newly assessable 17 binding rows have not yet been rescored. The guard and report were published on origin/master as fa01b1ae6e10d8d8b5e88d06cd9fc9c11d98941e, with both remote file blobs verified.

Next: score those 17 rows on the frozen axes as an explicitly post hoc reassessment, then update the combined result without rewriting the original blinded subset.
