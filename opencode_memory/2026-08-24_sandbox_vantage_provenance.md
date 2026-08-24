# 2026-08-24 — sandbox vantage rule: provenance audit + fix

## What was done

User relayed the other seat's self-audit (Claude Code L2520, 2026-08-24T13:08Z) of the
`## Sandboxed observability` section of `/data/agentic_trading/AGENTS.md` (lines 81-140).
Asked me to review accuracy and adjudicate stay/revert.

## Key facts settled

- **Provenance** (from `fb55eadf…jsonl` L830/L859/L1633/L1650):
  - Lines 83-84 (core rule): USER-SUPPLIED verbatim (L830).
  - Lines 86-96 (founding failure narrative): ASSISTANT-AUTHORED, built on user data (L824).
  - Lines 88-89, 126-127, 129-132 (first extension): ASSISTANT-AUTHORED, self-flagged (L859).
  - Lines 98-124 (mechanism subsection): USER-SUPPLIED verbatim spec (L1633), agent editorial (L1650).
- **Technical claims verified live**:
  - Host netns `net:[4026531833]` — exact match (AGENTS.md:120).
  - Sandbox netns `net:[4026533839]` — matches documented class.
  - `ss` empty + services alive from sandbox — reproduced (bwrap probe).
  - Fail-closed port guard present in `launch_qwen38_27b_fp8.sh:115-130`.
  - "nvidia-smi in BOTH lists" — CORRECT (project `.claude/settings.json:4` allow + user `~/.claude/settings.json:37-38` excludedCommands). My "defect #2" was a false positive.
- **Unverified claims** (no live CC sandbox to probe):
  - Seccomp sandbox value = 2 (my bwrap probe showed 0).
  - PID/filesystem namespace sharing in CC (doc+transcript supported only).
  - `/dev/nvidia*` absent from CC sandbox (my crude bwrap still sees them).

## Adjudication

**Stay: all.** No reverts. One real defect found and fixed:

- `AGENTS.md:134` — `swap_model.py` → `llm_swap.py` (file was retired 2026-08-23;
  `claude_sandbox_gpu_switch.md:39-40` documents the retirement).

## Durable artifact

- Commit `5c2d91fc`: `AGENTS.md: fix stale swap_model.py token (retired 2026-08-23; real one is llm_swap.py)`
  - 1 file changed, 1 insertion, 1 deletion.

## Open / next

- The Seccomp=2 claim and `/dev/nvidia*` absence claim in AGENTS.md remain unverified by
  direct probe (need a live CC sandbox process). Low priority — doc-supported.
