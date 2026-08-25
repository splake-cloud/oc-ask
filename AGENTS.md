# Agent notes (oc-ask seat)

## Answer detail

The CLI system prompt caps responses at "fewer than 4 lines" and "one word answers
are best", EXCEPT when the user asks for detail. Analysis, diagnosis, design,
trade-off, comparison, review, verification and verify requests ARE detail requests —
the cap does not apply. Answer those completely: every distinct mechanism, option or
failure mode you actually have, each with the observation or evidence that settles it.
Stop when the content is exhausted, not at a line count.

When VERIFY or VERIFICATION is instructed, every claim carries three parts:

    CLAIM | VERIFY METHOD | PROOF

PROOF is the verbatim output of the command you ran, or a file:line citation — the
evidence itself, pasted. A description of the check, a summary of what it showed, or
a restatement of the claim is not proof. A claim you cannot prove stays in the list
with its PROOF cell reading UNVERIFIED and why; dropping it is the defect this
prevents.

Tool-call turns, lookups and single-fact answers stay short. Completeness on the
question asked is the target; length is not.

## Session memory — `opencode_memory/`

This seat keeps a durable session-memory layer in `opencode_memory/`:
- `INDEX.md` — one line per memory card, newest first.
- `YYYY-MM-DD_<topic>.md` — one card per significant session/thread.

Conventions (these define the trigger phrases — a fresh session should follow them
from this file alone):

- **User says "reorient me", "what did we decide", or asks about past work** → read
  `opencode_memory/INDEX.md`, open the matching card(s), reorient the user. If the
  answer isn't in a card, check raw transcripts: opencode sessions in
  `~/.local/share/opencode/opencode.db` (sqlite tables `session`, `session_message`),
  Claude Code sessions in `~/.claude/projects/<project>/*.jsonl`.
- **User says "write a session receipt"** (or "remember this", "save the session") →
  distill the current session into a new card `YYYY-MM-DD_<topic>.md` with: what was
  built/decided, key facts settled (with file paths), open/next items. Then add one
  line at the top of `INDEX.md`. Distill — don't paste the transcript.
- **Write receipts proactively** when a thread ends with a durable artifact (files
  created/modified, design decided, tooling installed). Don't wait to be asked for
  anything the user would want to find next session.
- Project-specific runbooks live in the project dirs themselves (e.g.
  `/data/models/stable_diffusion/comfyui/WAN22_I2V_RUNBOOK.md`); memory cards point
  at them rather than duplicating their content.

## Sandboxed observability

From sandboxed context, host-loopback port state is unobservable. Never act on "server down /
port free" observed from a sandboxed command; verify with an unsandboxed/host check first.

The sandbox has its own network namespace, so `ss` returns empty and connect returns
ECONNREFUSED **as the default view, with every service alive**. Absence of observation is not
observation of absence. Same class: `nvidia-smi` failing to reach the driver, and a path reading
read-only — both are facts about the vantage point, not about the host.

The founding failure (2026-08-23: "all servers down, ports free" from a sandboxed `ss` while
:8011/:8081/:8765 served HTTP 200) is documented in `/data/agentic_trading/docs/claude_sandbox_gpu_switch.md`.

### The mechanism

Vantage is decided by **`excludedCommands` matching on the command string, all-or-nothing per
call**: when ANY part of a compound command matches an excluded entry, the WHOLE command runs
unsandboxed. Pre-allow is a SEPARATE layer and does nothing for vantage — conflating them is
the trap.

Operationally:

1. **The call that makes a host-dependent decision must itself match an excluded pattern** —
   e.g. `llm-alloc ...`, `bash scripts/launch_*.sh`. Only then are its own `curl`/`ss`/port
   checks trustworthy.
2. **A call built only from sandboxable primitives (`bash -c`, `curl`, `setsid`, `nohup`) is
   sandboxed even when it auto-runs with no prompt.**
3. **In-call vantage test:** `readlink /proc/self/ns/net` — host is `net:[4026531833]`; anything
   `40265338xx`/`40265339xx` is a fresh sandbox netns. Or `grep Seccomp /proc/self/status`
   (host 0, sandbox 2).
4. **One call, one vantage.** A sandboxed verifier must never veto a host-side decision.

NOT all namespaces are separated: the PID namespace and the filesystem ARE shared, so `pgrep`
and file reads are reliable from either vantage. It is the NETWORK namespace that isolates.

Rules: a prior positive observation outranks a later negative one taken from a different
vantage. State the vantage in the claim ("not visible from this sandbox"), never as world-fact.
Checks that gate an action must fail CLOSED when the vantage is unreliable — refusing because
the endpoint is unreachable is correct; concluding it is free is not.

Model-management commands (llm_alloc.py, llm_swap.py, nvidia-smi, launchers, the quality-arm
runner) are host-side by design. They are excluded from the sandbox only while the GPU switch is
ON — `python3 /data/agentic_trading/scripts/claude_sandbox_gpu.py status|on|off` (OFF default;
new sessions only; full entry list in `/data/agentic_trading/docs/claude_sandbox_gpu_switch.md`). An in-place patch
to the live vllm runtime still requires explicit PM go plus the diff first.

_Ported verbatim from `/data/agentic_trading/AGENTS.md` (2026-08-25): the
**Answer detail** and **Sandboxed observability** sections, unchanged except that
the two `docs/...` references in the latter were absolutized so they resolve from
this root. Both are behavioural rules that hold in any seat — answer shape and
host-sandbox vantage are not properties of a project. Keep the two copies in step._
