# What this directory is

Durable session memory for this seat. The conventions that govern it live in
`../AGENTS.md` (auto-loaded every session started here) — this file exists so the
directory is self-explanatory even if AGENTS.md is never read.

**"Write a session receipt"** (or "remember this", "save the session"):
distill the current session into `YYYY-MM-DD_<topic>.md`:
1. what was built or decided
2. key facts settled, with file paths
3. open / next items
then add one line at the top of `INDEX.md` (newest first). Distill — don't paste
the transcript.

**"Reorient me" / "what did we decide" / past-work questions:**
read `INDEX.md`, open the matching card(s), answer from them. If the answer isn't
in a card, check raw transcripts:
- opencode: `sqlite3 ~/.local/share/opencode/opencode.db` — tables `session`, `session_message`
- Claude Code: `~/.claude/projects/<project>/*.jsonl`

**Proactive receipts:** when a thread ends with a durable artifact (files
created/modified, design decided, tooling installed), write the receipt without
being asked.

**Project runbooks** live in the project dirs (e.g.
`/data/models/stable_diffusion/comfyui/WAN22_I2V_RUNBOOK.md`); cards point at
them, never duplicate them.
