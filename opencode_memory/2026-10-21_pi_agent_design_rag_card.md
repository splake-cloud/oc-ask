# Pi agent design — RAG card authored + shipped (2026-10-21)

**Built:** a `system_processes` RAG card documenting how the pi agent design works, shipped to all three roots.
Retrieval: `bash scripts/rag-search "project shadows global pi agent card"` (or "tools grant is the role",
"pi subagents do not auto-load AGENTS.md"). Top-hit on all three probes; live index 9 rows, 0 missing/stale/zero-vectors.

**Card:** `pi-agent-design#__process__` in the `system_processes` well, authored as a new AUTHORED tuple in
`scripts/rag_verifier/harvest_system_processes.py` (the well's harvester; fingerprint = the file itself, so the
edit moved the stage automatically). Version stamped 2026-10-21 by `build()`.

**What the card settles** (all grounded in files opened this session, 2026-10-20/21):
- **Two-layer registry**: project `.pi/agents/<name>.md` (loaded only for sessions rooted there, after trust) vs
  global `~/.pi/agent/agents/<name>.md` (every session, any root). **Project shadows global** (and shadows
  built-in agent types of the same name). Same two-layer split for `models.json`.
- **Role is per-card, enforced by the `tools:` whitelist** — not prompt prose. `qwen38-reviewer` (jett-8012) =
  `read, bash, ls, grep, find` (no write/edit tool → read-only by construction); `qwen38-collab`/`qwen-coder` =
  write+edit. The same :8012 server also serves write-enabled `semantic-worker`/`semantic-worker-long`
  (global cards from the Research Agent env; `jett-8012-long` = same baseUrl, maxTokens 65536 vs 32768).
- **author ≠ reviewer** doctrine is structural via the tool grant: a PASS is about a state the reviewer never created.
- **Card = complete contract** (pi subagents never load AGENTS.md — consistent with the 2026-10-18 F1 fix).
- **Inventory** of all three card dirs on the box + the **shadowing/drift hazard**: the 3 AT lane cards
  (qwen-coder, qwen38-collab, qwen38-reviewer) are byte-identical duplicates across both layers (global created
  2026-09-01, AT copies 2026-09-02); editing only one copy silently diverges AT vs non-AT sessions. Verify with
  `diff` across the two paths.
- Trap noted honestly: `bash` is a residual write channel — the guarantee is the ABSENCE of write/edit tool
  grants, constrained further by the card body, not airtight at the tool layer.

**Ship path used** (Checklist H, RAG.md §0.5): harvester edit → `scan-stage --groups system_processes` →
`seed-pending` per root (mid via `--remote-embed http://127.0.0.1:8765/embed` — serving root, 4B; small + full
via `--device cpu`, 9 cards) → status live ×3 → §0.2 index-diff block → live-service rag-search ×3 (top hit each).
Note: another session had staged a 21:35 change to this well; my full-root seed flushed both.

**Same day, same well:** the `git-commit-and-push-discipline` card's push section was stale (pre-2026-10-20 text: "pushing the shared linear master is FORBIDDEN") — updated to the simplified rule 8 (trailer gate, canonical 5 steps, gate-fail = stop and report, escape hatch deleted; plus the 2026-10-21 codex/root gate-fail episode as the worked example). Reseeded + verified: old phrasing keyed-gone, new phrasing top-hit live.

**Open / follow-ups:**
- The duplicated AT lane cards are still two copies each — consolidation (or a sync gate) is a PM decision, not
  made this session.
- `/data/research_agent/.pi/agents/` also has scoped copies of fast-coder/search_agent/sqlmesh-health — the card
  lists them as inventory; no cross-project dedup was attempted.
