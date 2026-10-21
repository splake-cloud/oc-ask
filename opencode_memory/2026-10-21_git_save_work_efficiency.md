# 2026-10-21 — commit+push efficiency: rule 13, save-work.sh, git card convergence

Continuation of the pi-agent-design session. The user asked why a spelled-out
commit+push took ~7 turns of reasoning, and ratified three fixes (items 1, 5, 6).

## What was built/decided

1. **AGENTS.md execution rule 13** ("Spelled-out procedures are code"): execute
   verbatim in order; a failed step is data, not an indictment; redesigning a
   spelled-out procedure mid-execution is a defect; redesign = separate explicit
   task. Written to the worktree file (live for all seats — doctrine loads from
   disk). **Publish BLOCKED** per the spelled-out stop condition: AGENTS.md worktree
   carries another session's uncommitted "Model evaluation runs" section, and 5
   unpushed commits from other seats (codex/root gpt-6 ×4: fd8b62f33, fef36dce6,
   2a838dfe8, 984597d6d; pi/jett-8012 ×1: 043faa22c) touch the file.

2. **`scripts/save-work.sh`** (built by qwen-coder, gated by main seat): encodes the
   AGENTS.md "Save your work" block (steps 1–4 incl. the buried-commit temp-index
   graft) with built-in verify. Exit codes: 0 saved, 2 usage, 3 stop-check
   (foreign commit touched a path), 4 verify mismatch, 5 network/vantage, 6
   rebase failed. `--selftest` = 7-case /tmp fixture suite (normal, idempotent,
   usage, ownership-pass, stop-check, graft, isolation). Gate round 1 FAILED
   (selftest crashed: relative `$0` after `cd`; case d didn't exercise rebase+push;
   `|| true` swallowed rebase/fetch failures) → bounce → round 2 passed 7/7 +
   independent rebase-conflict probe (exit 6, origin untouched). **Dogfooded for its
   own publish**: commit `90cfb5d9c` → graft `ac42ddbd2` on origin/master (~15 s,
   all steps + verify). **Wiring into doctrine is HELD for PM ratification.**

3. **RAG git card convergence** (item 5): `git-commit-and-push-discipline` card in
   `scripts/rag_verifier/harvest_system_processes.py` — 2d now points at the
   AGENTS.md "Save your work" block as single authority (stale 5-step restatement,
   "rules 1-5", "(6a a-e)", "(6)", "(8)" numbering removed; deprecation note kept);
   payload push/key_commands/triggers updated (ownership gate, graft commands,
   new trigger vocab). Reseeded full/mid/small, all live; live retrieval verified
   (new text serves; old phrasing no longer surfaces the old text).

## Key facts settled

- Root causes of the inefficiency (user-facing diagnosis): (1) treating spelled-out
  procedure as prose to improve, (2) working from a stale snapshot of the doctrine
  (file rewritten concurrently), (3) interpretation instead of observation,
  (4) turns ending in promises.
- The spelled-out procedure, executed verbatim, takes ~30 s (this session: 3.3 s for
  the graft alone; 15 s end-to-end via the script).
- `refresh_planner.py seed-pending` supports `--groups` / `--root`; **never pipe a
  long GPU seeder into `head`** — SIGPIPE killed a seeder mid-table_recipes and
  left the full-root data_table index partial; repaired by the full-queue reseed
  (backups in `verifier_kb/_rebuild_backup/`).

## Open / next

- PM ratifies → wire `save-work.sh` into the doctrine (one-line reference in the
  "Save your work" block) — and consider whether rule 13 gets the "re-read the file,
  not a remembered copy" addendum.
- AGENTS.md rule 13 publish: unblocks when the other seats push their AGENTS.md
  commits (or PM directs the graft despite the foreign-content stop condition).
- Local master carries pre-graft twin SHAs (content-identical to origin) — cosmetic.
