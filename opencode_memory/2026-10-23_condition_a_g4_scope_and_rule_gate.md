# Condition-A G4 scope rerun and decision-rule gate

Session: `01a16593-0275-7aa3-8aad-e7e35606740d` (Codex, GPT-6, `/data/agentic_trading`), 2026-10-23.

## Outcome

The G4 widened-scope rerun kept the prior :8011 reasoning model and normal Research Agent Pi harness. The first three valid complete sessions (201–203) missed both G4 target decisions as full OPEN/Y entries: 0/3 on the R5 adequacy floor and 0/3 on the held-out calibration split. Run 204 was complete but unscored because it was launched after session 201 was mistakenly treated as incomplete. Full IDs, transcripts, quotes, and usage: `/data/agentic_trading/docs/methodology_condition_a_g4_scope_rerun_2026-10-23.md`; raw evidence: `/tmp/condition_a_g4_scope_20261023/`.

The structural control was implemented in the canonical Research Agent idea template `/data/research_agent/prompts/idea.template.md`, its gate transport `/data/research_agent/prompts/idea.md`, the deterministic validator `/data/agentic_trading/scripts/idea_rule_closure_gate.py`, and the ledger authorize preflight `/data/agentic_trading/ontology_lab/study_ledger.py`. The template requires mapped verdict states, explicit combinations for compound gates, and headline rules for multi-block designs. The transport requires semantic completeness checks; the validator rejects missing structural fields; the ledger refuses authorize on validator failure before opening its DB. Verification and known limits: `/data/agentic_trading/docs/idea_rule_closure_gate_2026-10-23.md`.

## Open / next

No live study was authorized or scored by this gate work. Existing ideas using the old template need a closure block before future authorization. The mechanical validator cannot prove that every prose concept has been registered, so the transport's semantic cross-check remains necessary. This session did not commit or publish the files. The AT worktree is shared and contains many unrelated edits; stage only this session's paths if later asked to save work.

## Completion update — authorization candidates

The PM selected two nonblocking candidate patterns plus PM review at authorization as the coverage control. The live idea transport now requires presenting review_candidates and dispositions with the authorization evidence; PM review supplies coverage. The scanner lists evaluative terms without same-line thresholds/rules and capitalized verdict labels absent from operative register mappings. Plain REDUNDANT support and operative-mapping suppression were corrected by the restored Qwen3.6 coding delegate; independent selftest passed 22 cases and independent label checks passed.

Frozen B5 lists REDUNDANT at line 29; G4 lists adequate fidelity at line 239; P5 lists vanishes at line 60. All nine non-CLOSED ideas were scanned once, including four VALIDATED studies; sources and study states were unchanged. Full candidate lists, hashes, and receipts: /data/agentic_trading/docs/idea_rule_closure_real_idea_audit_2026-10-23.md. Shared authorization action is now gated as well as the CLI. This scoped work is complete and uncommitted. The mechanical check still only validates declared rows; the PM candidate review is the selected coverage control.

An old Pi scanner-repair run was found still saturating GPU2 and interrupted by its known exec session. At the PM's explicit request, qwen38-instruct-gpu2.service was stopped and qwen36-coder.service started. GPU2/:8081 now serves qwen3.6-35b-a3b-q8; the GPU2 RAG process and /health stayed healthy and unchanged.
