# Proxy-substitution tune arc closed — 2026-10-21

## Settled decision

The arc closed as inconclusive at the target gate: no repeatable, keyed real-packet proxy-substitution error was demonstrated, so there is no justified new fine-tune target. No sealed test was opened. This does not show that the skill is unlearnable. Existing tested adapters were rejected separately.

## Durable records

- Admin docket: /data/agentic_trading/training/proxy_substitution_closeout_20261021/ADMIN_DOCKET.md (commit b0c83f77e).
- Three local diagnostic-pool rows: /data/agentic_trading/training/proxy_substitution_closeout_20261021/DIAGNOSTIC_POOL_LEDGER.md (same commit). They cover the illustrative PPA triplet, S02–S08 triplets, and the 20-pair direct-vLLM diagnostic. Canonical docs/data_pools/POOL_LEDGER.yaml was not changed because its contract is one row per /data/parquet dataset.
- Tune ledger close receipt: /data/agentic_trading/training/proxy_substitution_closeout_20261021/LEDGER_CLOSE_RECEIPT.md (commit 24a75c8b9).
- Earlier directional observation: /data/agentic_trading/training/PROXY_SUBSTITUTION_TRIPLET_OBSERVATION_20261021.md (commit d079bd523).
- PD-00172 in /data/research_agent/telemetry/pending_decisions.jsonl resolved DECIDED/REJECT; ontology_lab/tune/tune_ledger.duckdb has all three proxy tune runs CLOSED. The remaining real17_continue_01 transitioned EVALUATED -> ADJUDICATED -> CLOSED via governed CLI with PD-00172.

## Diagnostic facts

The repaired S02–S08 baseline passed six of seven strict triplets. S03 proxy item_160 was keyed NOT_ESTABLISHED but returned NO in 3/5; S05 proxy item_149 returned NO in 1/5 after repair. Across 35 proxy responses: four false NO, zero YES overclaims. Neither error met the >=4/5 repeatability rule. S03 remains counted as a model error; its as-of positive-member wording is an open surface repair. S05 item_107 and item_138 evidence were repaired to link Fieldstone and the Equity Capital Contribution Agreement; repaired outcomes were 5/5 YES and 5/5 NO. Item_149 was 4/5 NOT_ESTABLISHED.

The exploratory direct-vLLM 20-pair run went 15/20 -> 20/20 pair passes with four worked pairs, but its six-pair improvement margin was mathematically unreachable from a 15/20 baseline; five favorable discordants give two-sided p=0.0625. Direct members were at ceiling, so a threshold shift was not excluded. Raw per-item repeats were not preserved in the docket.

## Open items, not active work

1. If S03 item_126 is reused in a frozen instrument, add explicit confirmation that the letter of credit remained in force on May 15, 2025.
2. False-refutation is a hypothesis for future keyed real-packet triplets. No tune or prompt change is authorized by this batch.
