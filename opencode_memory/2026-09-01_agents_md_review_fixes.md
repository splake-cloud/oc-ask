# 2026-09-01 — AGENTS.md review + 11 fixes applied via qwen-coder

## What was built/decided
- Reviewed `/data/agentic_trading/AGENTS.md` (11.6 KB, multi-root doctrine file). Verdict:
  enforcement design (evidence-as-artifact, bounded probing, fail-closed vantage,
  author≠reviewer) is sound; structural weaknesses = two harnesses in one file (pi vs
  opencode), three coexisting evidence regimes with no precedence, RAG "ground truth"
  overclaim, unenforceable "binding" language, no last-modified marker.
- PM approved 10 fixes (F1–F10) → dispatched as ONE EDIT mission to `qwen-coder`
  (:8081, qwen3.6-35b-a3b-q8) via `scripts/agentic_client.py agentic_chat` + `edit_file`.
  11 edit ops (F9 split into E10/E11), preflight = every old_string occurs exactly once.
- All 11 applied first try. **APPLIED + VERIFIED.**

## Key facts settled
- Deliverable: `/data/agentic_trading/AGENTS.md` — changed hunks:
  E1 `updated: 2026-07-09` marker + precedence paragraph (top); E2 rule-3 self-enforced
  note; E3 "best prior, not ground truth"; E4 4-line-cap made seat-conditional; E5
  Evidence-tiers block (verify-run > VERIFY table > one-line); E6 "mandatory field of the
  envelope"; E7 delegation mechanism seat-conditional (task tool/opencode vs envelope/pi);
  E8 rubric pointer on "scored finding"; E9 verify-run failure = UNEXECUTED path;
  E10 session memory cross-seat by design; E11 one-thread-one-card dedup.
- Pre-image: `/tmp/AGENTS.md.pre-20260709` (will vanish on reboot).
- Mission + audit trail: `/data/agentic_trading/.ai/staging/agents-md-fixes/`
  (`mission.md`, `response.md`, `transcript.json`, `run_dispatch.py`).
- Verification transcripts (verify-run):
  `verify/agents-md-fixes-diff.20260901T094944Z.txt`,
  `verify/agents-md-fixes-grep.20260901T094951Z.txt` (grep exit 0).
- Dispatch mechanics that worked: `agentic_chat(ENDPOINT=http://127.0.0.1:8081/v1,
  model=qwen3.6-35b-a3b-q8)` with the `edit_file` tool; JSON-escaped old/new literals in
  user prompt; delegate reported 11/11 in loop 1, final answer loop 2. Confirms the
  09-01 sqlmesh card's doctrine: exact-literal spec + BLOCKED-instead-of-guessing = clean
  first-shot edit delivery (this was a 35B first-shot 11/11, matching its spec-density
  envelope: 11 small clauses < the ~8-clause degradation zone because each was a verbatim
  copy, not a design decision).

## BRANCH COLLAPSE — COMPLETE 09-01 10:30 UTC (supersedes all prior open items on branch state)
- PM doctrine: system serves the research, not the reverse. One line, zero branch navigation.
- Final state: **master is the only branch, local and remote.** Tree on master, clean, in sync.
  All 75 other local + 57 remote branches deleted. Iron-fly merged into master (merge c6958f10
  line; opencode.jsonc conflict resolved to the post-08-31 PM-ruling side = byte-identical to the
  live config; F1 + doctrine + seat config verified on master via verify transcripts).
- Safety net: `.ai/archive/all-branches-pre-collapse-20260901.bundle` (687MB, 133 refs, verified;
  gitignored, disk-only — resurrect any old study with `git bundle list-heads` + checkout).
- WIP closeout commit 63aac60f (iv_weekly_substrate phase + 09-01 receipts) is ON master.
- `outputs/fly_paths_*.parquet` (2×145MB) intentionally NOT in git (GitHub 100MB limit); on disk,
  gitignored. All work otherwise committed.
- Nightly acceptance: daily_eod_build fires 23:31 UTC 09-01 from master (has F1).
- Recurrence rule: **APPLIED 09-01 10:33** — `## Git line discipline` section now in AGENTS.md
  (commit 6c775274 on master, via qwen-coder EDIT mission, verify transcript
  `verify/gitline-diff.20260901T103323Z.txt`): tree always on master; no checkout/create of a
  branch without explicit PM go (incident named as the precedent); committed=kept;
  heavy binaries never in git; isolation only via PM-decided worktree. `updated:` marker bumped
  to 2026-09-01.

## Open / next
- None. RESOLVED 09-01: repo IS under git — committed as `e5d700aa` on branch
  `iron-fly-economic-baseline` (AGENTS.md + staging audit + both verify transcripts;
  `/tmp` pre-image no longer the only rollback copy — `git show e7e6fe5b:AGENTS.md` is
  the pre-fix byte image).
- **SUPERSEDED 09-01 (PM correction):** the hand-built `delegate.ts` plan is unnecessary —
  the pi repo (github.com/earendil-works/pi) ships `examples/extensions/subagent/`
  (also in the installed npm package): registers tool `subagent` (single / parallel /
  chain modes), agents = `~/.pi/agent/agents/*.md` frontmatter (name/description/tools/
  model), spawns `pi --mode json -p --no-session [--model X/Y] [--tools a,b] [--append-
  system-prompt tmp]`, streams + usage tracking. Install = symlink index.ts+agents.ts
  into `~/.pi/agent/extensions/subagent/` + author agent mds (`model: jett-8011/qwen3.6-
  35b-a3b-q8` coder; `jett-8012` reviewer). Draft-specific extras (readonly default flag,
  timeout param, embedded 5-rules constant) have no built-in equivalent — rules go in the
  agent md body. Then AGENTS.md E7 "delegate envelope in pi" becomes "subagent tool,
  agents qwen-coder / qwen38-reviewer" = truly seat-aware. Not installed yet (no go).
