# 2026-08-25 — AGENTS.md double-load: symlinking a second root injects doctrine twice

## What was found

opencode assembles its instruction files from **two independent routes**, and merges
both into one set:

1. **Directory search** — from the session's launch dir, look for `AGENTS.md`, then
   climb to the parent, up to the project/worktree root. First filename that hits wins
   (`AGENTS.md` short-circuits `CLAUDE.md` and `CONTEXT.md`).
2. **The global config's `instructions` list** — absolute paths, read regardless of
   where the session was launched. Ours holds `/data/agentic_trading/AGENTS.md`.

The set is deduped by **path TEXT** (`path.resolve`), **not** by realpath. So a symlink
is a *second distinct path to the same file* and the whole doctrine is injected twice.

`~/oc-ask/AGENTS.md` had been symlinked to `/data/agentic_trading/AGENTS.md`. Result:
every oc-ask request carried the doctrine twice.

## Measured (raw-packet probe, not inference)

opencode labels each loaded file in the system prompt as `Instructions from: <path>`,
so the sources are named rather than guessed.

| Root | `Instructions from:` | System prompt |
|---|---|---|
| `~/oc-ask` **with** symlink | `~/oc-ask/AGENTS.md` + `/data/agentic_trading/AGENTS.md` | 28,789 chars |
| `~/oc-ask` after removal | `/data/agentic_trading/AGENTS.md` | 19,192 chars |
| `/var/tmp/oc_probe_b` (no local AGENTS.md) | `/data/agentic_trading/AGENTS.md` | 19,179 chars |
| `/data/agentic_trading` (oc_dispatch default) | `/data/agentic_trading/AGENTS.md` | 19,204 chars |
| `/var/tmp/oc_attach_probe` (seat workdir) | `/data/agentic_trading/AGENTS.md` | 19,189 chars |

~9.6 KB / ~2.4k tokens duplicated on **every** oc-ask request.

## Why oc-seat was never affected

Two different reasons, both verified:

- **Workdir launches** (`rig/oc_server.sh ask <workdir>`): none of the 151
  `/var/tmp/oc_*` dirs contains an `AGENTS.md` at any depth, and neither
  `/var/tmp/AGENTS.md` nor `/AGENTS.md` exists. Route 1 finds nothing.
- **`/data/agentic_trading` launches** (`scripts/oc_dispatch.py`, `DEFAULT_DIR`):
  route 1 *does* find the file, but produces the **identical path string** that
  `instructions` names, so the dedupe collapses them correctly.

Same path string → deduped. Two path strings for one file → not deduped. That is the
whole rule.

## The probe recipe (reusable)

1. Tiny OpenAI-compatible HTTP server that appends each request body to a log and
   returns a canned SSE completion.
2. Register it as a provider **project-level** — `<root>/.opencode/opencode.json` —
   which merges additively, so the trunk-owned global `opencode.jsonc` is never edited.
3. `OPENCODE_DISABLE_MODELS_FETCH=1 opencode run -m probe/probe-model "hi"`
4. Grep the captured system prompt for `Instructions from: (\S+)` and count doctrine markers.

Gotchas that cost time: the **first** run in a new root pays one-time project setup and
often times out — just re-run. `pkill -f probe_server.py` matches its own shell and kills
it; use `pgrep/pkill -f '[p]robe_server'`.

## Resolution

- `oc-ask@9906220` — deleted `~/oc-ask/AGENTS.md`. `instructions` already delivers the
  doctrine globally, so nothing was lost. Neither `CLAUDE.md` nor `CONTEXT.md` exists
  there, so nothing substitutes.
- `market_data@623a81e4` — the multi-root comment in `/data/agentic_trading/AGENTS.md`
  had advised *"Do not fork a second copy for another root; symlink it."* Symlinking was
  the failure mode. Now reads: reference it via `instructions`.

## Lesson

The regression was introduced by copying two "universal" sections from
`/data/agentic_trading/AGENTS.md` into `~/oc-ask/AGENTS.md` on a *reasoned* assumption
that the seat was missing them. It wasn't — `instructions` had delivered them since
2026-07-25. Reading the loader's minified source produced a confident and wrong model
twice over; only the packet capture settled it. **Don't propose a fix for an
instruction-loading question from code reading — capture the prompt.**
