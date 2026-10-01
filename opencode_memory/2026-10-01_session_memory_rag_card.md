# Session memory bank — RAG card (opencode_memory + raw transcript layer)

Session: pi 01a0f5f1-58d1-7483-a988-bcb8629a3f90 (pi-coding-agent, qwen3.8-27b-fp8, seat jett-8012, /data/research_agent), 2026-10-01.

## What was built

PM asked for a RAG card detailing the session memory bank so a fresh session can find it
and retrieve FULL runs from the index/log. Card authored in the `lifecycle_contracts`
well (the established home for hand-authored station narrative cards, per the
study-state-ledger precedent) and seeded live on both RAG roots.

## Key facts (verified)

- **Card**: `session-memory-bank` — new AUTHORED entry in
  `/data/agentic_trading/scripts/rag_verifier/harvest_lifecycle_contracts.py`
  (survives re-stage; well now 43 cards, 30 triggers, 6 citation refs).
- **Card content**:
  - bank layout: `/home/user/oc-ask/opencode_memory/` — dated cards `YYYY-MM-DD_<topic>.md`,
    `INDEX.md` (newest first, one line per session), `session_id.md` (append-only session-ID
    log), `README.md` (protocol), system card `2026-08-24_opencode_memory_system.md`;
    git repo `/home/user/oc-ask` → `github.com/splake-cloud/oc-ask.git`.
  - protocol trigger phrases: "write a session receipt" / "remember this" / "save the session"
    → card + INDEX line + session_id entry; "reorient me" / "what did we decide" → INDEX → card.
  - drift noted: the auto-loaded protocol file `/home/user/oc-ask/AGENTS.md` (symlink to
    /data/agentic_trading/AGENTS.md) was REMOVED in commit `9906220` — the protocol now lives
    in README.md + the system card; other-cwd sessions use "check opencode_memory in /home/user/oc-ask".
  - raw transcript layer (full-run retrieval): opencode sqlite
    `~/.local/share/opencode/opencode.db` (~5.5 GB; tables `session` (id ses_..., title,
    directory, agent, model, tokens, times), `session_message`, `part` ~265k rows);
    pi JSONL `~/.pi/agent/sessions/<cwd-slug>/<ISO-timestamp>_<session-uuid>.jsonl`
    (session ID = the UUID; assistant messages carry the ACTUAL runtime provider/model);
    pi subagent sidechains `/tmp/pi-subagents-<uid>/<cwd-slug>/<parent-session-uuid>/tasks/<agent-id>.output`
    (EPHEMERAL); Claude Code `~/.claude/projects/<project>/*.jsonl`.
  - retrieval chain: INDEX.md / session_id.md (by session id) → card → raw transcript by id.
- **Seeding**: full root via `--remote-embed http://127.0.0.1:8765/embed` (live 8B on GPU2;
  no GPU had the 28 GB floor), small root local CPU (0.6B). `status --root all`:
  lifecycle_contracts full:live small:live, 43 rows each.
- **Checklist E**: negative-before clean (both verify phrases retrieved only unrelated cards);
  after: `opencode_memory session_id.md` → 5.688, `pi session transcript sessions directory
  full run retrieval` → 4.625, `where do I record a session id` → 3.750 (all top hit = the card).
- **Committed**: `d05b8d7c` pushed to market_data master (harvester file only, path-scoped add,
  Agent-Print trailer).

## Open / next

- **Pre-existing harvester bug** (unfixed, out of scope): `harvest_ontology_decisions.py:223`
  `arts[:8]` on a dict → `KeyError: slice(None, 8, None)` — breaks a full `scan-stage`
  (had to use `--groups lifecycle_contracts`).
- **Duplicate session entries**: `session_id.md` carries two near-identical 01a0f5f1 pairs
  (pre-existing from the earlier part of this session; append-only log left untouched).
