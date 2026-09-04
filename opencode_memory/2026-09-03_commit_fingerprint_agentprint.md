# 2026-09-03 — Commit fingerprint (Agent-Print) for all agents + backfill of 4 pushed commits — **COMPLETE**

**Status: DONE (2026-09-03 ~18:30 UTC).** All three ratified decisions executed + pushed:
(1) `Agent-Print:` rule written to AGENTS.md rule 6, (2) commit-msg hook built+installed+committed,
(3) the 4 pushed commits backfilled via commit-tree rewrite + `--force-with-lease`.
Final master = `507d6dd2` (origin==local). Receipts: `verify/agentprint-backfill-final.20260903T182255Z.txt`,
`verify/commit-msg-hook-selftest.20260903T182502Z.txt`, `verify/agentprint-all-done.20260903T182945Z.txt`.
Recovery bundle still at `/tmp/opencode/pre-agentprint-20260903.bundle` (anchor `22889f89`).

**Thread:** session `ses_f9b2c82a5ffewth1VIY59oXzJr` ("Data catalog fragmentation across six
registry systems"). P0/P1 work (spx_15min RESOLVED `cb845973`; view path-rot checker
`aaf118cf` + EOD wire `d3983b94` + review fixes `6e9d4c4e`) is CLOSED and pushed. This card is
the **commit-fingerprint** task that followed.

## What was ratified (PM decisions, verbatim "1 yes, 3 - hook, 4 - fix the commits")
1. **Format = `Agent-Print:`** (not `Co-Authored-By:`). Canonical trailer:
   `Agent-Print: <seat> (<model-id>)`, e.g. `Agent-Print: opencode (qwen3.8-27b-fp8)`.
   It names the agent (seat + model), not a person; primary author (user.name/email) stays as-is.
   Applies to every agent-authored commit (main tree, branch, worktree, merge, cherry-pick).
   Pushing carries it with no extra step (trailer lives in the commit).
   Generalizes the Claude-only rule in CLAUDE.md §"Commit Attribution" (which stays for Claude).
2. **Mechanical enforcement = a `commit-msg` hook** that REJECTS a commit lacking the trailer.
   Repo hook convention (match `pre-commit`): source-of-truth in `scripts/hooks/commit-msg`
   (version-controlled), active copy installed in `.git/hooks/commit-msg` (not tracked).
   Override = `git commit --no-verify` (existing convention). Hook must ignore `#` comment lines
   (commit-msg sees the raw file before comment-strip).
3. **Fix the 4 already-pushed commits** = backfill the trailer via history rewrite + force-push
   (PM overrode the "forward-looking only" recommendation).

## The 4 commits to backfill (all `Steve <splake@grandview-pr.com>`, no trailer)
- `cb845973` rag: mark spx_15min dual-contract prior RESOLVED
- `aaf118cf` warehouse: add report-only view path-rot checker
- `d3983b94` eod: wire view path-rot checker as non-blocking step 11
- `6e9d4c4e` warehouse: fix view_path_check review findings D1-D6 + minors

**Blast radius:** they are interleaved with other sessions' commits in a linear range
(`cb845973^..master`). Rewriting them cascades new SHAs through the whole range (git chain;
trees of the non-target commits are unchanged, only the 4 messages gain the trailer).
My seat fingerprint for all 4: `Agent-Print: opencode (qwen3.8-27b-fp8)`.

## Concurrent-session conflict (RESOLVED by waiting)
A **concurrent active session** `ses_f979d61bfffekukI0Tm74SydQ7` ("Fly gamma path-contrast")
had committed **`22889f89`** to local master but NOT pushed it (origin was still `6e9d4c4e`),
and the shared worktree was dirty. Force-pushing then would have pushed+desynced that session.
**PM chose "wait for it to push, then rewrite."** It pushed (`origin/master` advanced to
`22889f89`), so the rewrite proceeded on the quiet master `22889f89`.

## How the backfill was done (reusable technique)
- **Not `git rebase`** (needs clean worktree; we share the worktree with a live session).
- **`git commit-tree` rebuild** (`/tmp/opencode/backfill_agentprint.py`): walks
  `cb845973^..master` oldest→newest, recreates each commit with `-F <exact-message>` preserving
  tree + author/committer identity + raw dates, changing ONLY the 4 target messages
  (append `\n\nAgent-Print: opencode (qwen3.8-27b-fp8)\n`). Touches NO working-tree files.
- **Key gotcha:** read the message from the RAW commit object (`git cat-file commit`, bytes after
  the first blank line), NOT `git log --format=%B` (which appends a trailing `\n` → would have
  altered every non-target commit's message). `commit-tree -F` stores the file bytes verbatim.
- **Ref update CAS-guarded:** `git update-ref refs/heads/master <new> <old=22889f89>` (fails if
  master moved) then `git push --force-with-lease=refs/heads/master:22889f89 origin master`.
- Verified: all 16 trees preserved, 12 non-target messages byte-identical, 4 targets +trailer,
  HEAD tree identical, `git diff old_head..new_head` empty, identity/dates IDENTICAL on the 4.

## Recovery backup (valid recovery point)
- Bundle: `/tmp/opencode/pre-agentprint-20260903.bundle` (590 MB, `bundle verify` = "complete
  history", anchor `22889f89`). Recreate if /tmp is cleared.
- Recovery: `git -C /data/agentic_trading fetch /tmp/opencode/pre-agentprint-20260903.bundle
  master:backup/pre-agentprint` then reset master to it.

## What was executed (final state)
- Backfill: 4 commits `cb845973 aaf118cf d3983b94 6e9d4c4e` → `1639c534 411784e4 bed346c6
  e8f5cd6a`, each +`Agent-Print: opencode (qwen3.8-27b-fp8)`; master `22889f89 → c4213a9f`
  (force-with-lease).
- Rule: AGENTS.md "Git line discipline" **rule 6** (Agent-Print), committed `507d6dd2`.
- Hook: `scripts/hooks/commit-msg` (qwen-coder BUILD) + active `.git/hooks/commit-msg`; committed
  in `507d6dd2`. Gate = `AGENT_PRINT_ENFORCE=1`; regex `^Agent-Print:[[:space:]]+[^[:space:]]+
  [[:space:]]+\(.*\)[[:space:]]*$`; comment lines skipped; `--no-verify` override. 5/5 self-test
  PASS (block no-trailer / block comment-only / block seat-only / pass trailer / pass gate-off).
- The fingerprint commit `507d6dd2` itself was made with `AGENT_PRINT_ENFORCE=1` (allow-path proof
  on a real commit).
- Unrelated `-readonly` duckdb line (pre-existing scratch) was EXCLUDED from `507d6dd2` and left
  as uncommitted scratch (restored to working tree; see Traps).

## Enforcement activation (PM 2026-09-03 ~23:10 UTC) — wire AGENT_PRINT_ENFORCE=1
- **Seam chosen = the opencode server's `EnvironmentFile`.** `opencode-server.service`
  ("single seat executor; the ONLY opencode server") reads
  `EnvironmentFile=-%h/.config/opencode-server.env`. That file (perms `-rw-------`, untracked,
  outside the repo) already holds `OPENCODE_SERVER_PASSWORD`. Appended one line:
  **`AGENT_PRINT_ENFORCE=1`** (verified present, line 3). Chose the env file over a unit
  `Environment=` because it needs NO `daemon-reload` (just a restart) and keeps the unit pristine.
- **PM ruling: universal.** "if any seat wants to commit they need to be named in its work" —
  no per-seat opt-out. The env var reaches every opencode session via inheritance
  (server → opencode → bash tool call → `git commit`), so every opencode seat's `git commit`
  runs with the gate on. Human commits never go through opencode, so they're unaffected.
- **Dormant until restart.** systemd reads `EnvironmentFile` only at process start. A plain
  restart (23:08) that precedes the edit (23:10) does NOT pick it up — the running server
  (PID 3732887) still lacks the var. Activation = `systemctl --user restart opencode-server.service`.
- **PM said "do it"** (authorize ME to trigger the restart). I ran
  `systemctl --user restart opencode-server.service` (accepted by systemd).

### CORRECTION (found after the restart): the opencode-server seam was the WRONG tree
- The restart did **NOT** end my session — because the committing seats are **not** children
  of `opencode-server.service`. They are **tmux-hosted `opencode` CLIs** (`opencode -s <id>`),
  each launched by a human typing `opencode -s …` into a tmux pane's interactive `-bash`.
  No systemd unit exists for them. My seat (PID 3732978) survived the server restart intact.
- Consequence: the `AGENT_PRINT_ENFORCE=1` in `~/.config/opencode-server.env` (and the
  server restart) only covers the headless `opencode serve` tree — **not** the CLI seats that
  actually commit. My own bash confirmed `AGENT_PRINT_ENFORCE=<unset>` post-restart.
  (The server var is left in place — harmless, and correct if anyone `opencode attach`es to
  the headless server, which would then be gated too.)

### The REAL seam = `~/.bashrc:304` (the agent-launch alias)
- The interactive CLI seats all launch via the alias (was): `alias opencode='env -u TMUX opencode'`.
- **Edited to:** `alias opencode='env -u TMUX AGENT_PRINT_ENFORCE=1 opencode'`.
- Why scoped to the alias (not a blanket `export` in .bashrc): `env VAR=1 opencode` puts the
  gate in the **opencode agent process** env only → propagates down to the agent's `git commit`
  (gated ✓), while a human typing `git commit` directly in their interactive bash is **not**
  self-declared (human commits NOT gated ✓). Exactly the "agent named, human not" rule.
- **No systemd, no restart, no session kill.** Forward-looking: every NEW `opencode` CLI seat
  launched via the alias is gated. Already-running seats (incl. this one) keep their old env
  (var unset) until they are relaunched.
- opencode 1.18.23 has **no** top-level `env` config key (the only `"env"` in
  `config/opencode/opencode.jsonc` is a `permission` pattern for the `env` command), so the
  alias was the correct central seam.

### Verified end-to-end (ran the installed `.git/hooks/commit-msg` under each env):
- Agent seat (gate ON, `AGENT_PRINT_ENFORCE=1`) + **no** trailer → **BLOCKED** rc=1 ✓
- Agent seat (gate ON) + `Agent-Print: opencode (qwen3.8-27b-fp8)` trailer → **PASS** rc=0 ✓
- Human (gate OFF) + **no** trailer → **PASS** rc=0 ✓
So the gate is **LIVE for all future CLI seats** (forward-looking).

### Scope limit (follow-on, separate): other launch paths
- The **pi seats** and the **qwen-coder** delegate launch through other paths (not this
  alias, not the headless server) and do NOT inherit `AGENT_PRINT_ENFORCE=1` — they need their
  own seams. Not yet done. Until then those seats are convention-enforced only (hook no-op).

## Open / follow-up
- **Wire the same `AGENT_PRINT_ENFORCE=1` seam into the pi seats + qwen-coder delegate**
  (their own launch mechanisms). Open opencode CLI seats are done (via the bashrc alias).
- The 4 backfilled commits' trailers name `opencode (qwen3.8-27b-fp8)`; if the PM prefers a
  different seat label it's a cosmetic re-rewrite (same technique).

## Traps
- `git` commands here MUST use `git -C /data/agentic_trading` (bare `git` is permission-denied).
- `rm` is permission-denied; do not plan cleanup around it.
- The rebase reword must NOT change any tree — verify `git diff <old-master> <new-master>` is empty
  (only the 4 commit messages differ) before force-pushing.
- Use `--force-with-lease`, never bare `--force`.
- Do NOT touch the other session's uncommitted memory card (`2026-09-03_l3_opex_modern_arm.md`)
  or its INDEX.md edit in `/home/user/oc-ask`.
