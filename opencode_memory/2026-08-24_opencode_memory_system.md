# 2026-08-24 — Session memory system (this layer)

User asked "how do you keep track of history of sessions" (Claude-Code-style
"reorient me on what we decided" flow). Settled the design and built it.

## What was built
- `/home/user/oc-ask/opencode_memory/` — this dir. Cards + `INDEX.md` (newest first).
- `/home/user/oc-ask/opencode_memory/README.md` — dir is self-explanatory.
- `/home/user/oc-ask/AGENTS.md` — **auto-loaded every session started in
  /home/user/oc-ask**; defines the trigger phrases so a fresh session knows the
  protocol from startup, without re-explanation:
  - "write a session receipt" / "remember this" / "save the session" → distill
    current session into `YYYY-MM-DD_<topic>.md` + one INDEX line.
  - "reorient me" / "what did we decide" → read INDEX.md, open matching card.
  - Proactive receipts on durable-artifact threads.

## Key facts settled
- Raw transcripts (backup layer, greppable):
  - opencode: sqlite `~/.local/share/opencode/opencode.db` — tables `session`,
    `session_message`, `part`. `select title from session order by rowid desc` works.
  - Claude Code: `~/.claude/projects/<project>/*.jsonl` (main project ≈ 214 MB).
- RAG has **no session-memory collection** (checked via `rag-search
  --collections`: 21 collections, none for sessions) — this layer is standalone.
- The convention phrase was originally a private session-only thing; the fix was
  to put the protocol in AGENTS.md (auto-load) + README (self-explanatory) so it
  survives across sessions.
- Gap: sessions started from a *different* cwd won't auto-load /home/user/oc-ask/AGENTS.md;
  then say "check opencode_memory in /home/user/oc-ask".
