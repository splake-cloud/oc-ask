# 2026-10-12 — teach-me extension: the build + learning-style reframe (pi seat jett-8011 / qwen3.8-27b-fp8)

**Session:** pi `01a126f9-8ba3-7397-b6d3-f7de16d7a1de` (started 2026-10-10; the learning-style
reframe work landed 2026-10-12). Commits `c26e2ae9f` (code) + `bf7a61a23` (scope doc), both
pushed; Agent-Print trailer `jett-8012` (see Seat note). This is the definitive reference for
"the teach-me build."

## What this is

`teach-me` is a pi extension: when the research agent makes a consequential decision that
involves machine-jargon, a short **teaching block** is generated on a dedicated **GPU2 teacher**
and appended *after* the primary's turn — **zero primary slowdown** (all teaching text is off the
primary's GPU/turn, emitted as a `CustomEntry` excluded from LLM context). The block explains the
concept in the form the user actually learns in.

The build spans phases (the compacted history of this session); the **learning-style reframe** is
the main work of this session and the thing you'll ask about.

## 2026-10-14 update — teacher relaunched + the enable_thinking bug (READ THIS)

The GPU2 fine-tune finished, releasing GPU2. The teacher was relaunched
(`scripts/launch_qwen38_27b_fp8.sh` with `PORT=8013 GPU=2 CTX=16384 UTIL=0.38
VENV=.../.venv-vllm-0.30.0 CUDA_HOME=/usr/local/cuda-13.2 VLLM_USE_V2_MODEL_RUNNER=0`),
health 200, port-owner pid 3210589 (pid file `/tmp/teach_teacher_8013.pid`). The
previously-blocked **live-teacher-generation smoke test** then ran and caught a real bug.

**The bug (load-bearing):** the teacher is a *reasoning* model (qwen3 + `reasoning_parser
qwen3`). With no disable-think, it spends its entire `max_tokens` (1200) on internal reasoning
and returns `content: null` (`finish_reason: length`, `reasoning_tokens: 1200`) → the teaching
block renders EMPTY. A plain "Return only the text" prompt is not enough for a reasoning model.
**Fix (commit `e5ae47daa`):** the extension's teacher request now sends
`chat_template_kwargs: { enable_thinking: false }` — verified live against :8013:
`reasoning_tokens` 1200→0, `content` null→a clean 2-3 sentence block + "On your work:" synthesis,
`finish_reason` length→stop, 136 completion tokens. `/no_think` alone was NOT enough (579
reasoning tokens still); only `chat_template_kwargs.enable_thinking=false` disables it fully.

**GPU2 co-residency (tight but stable):** :8081 (qwen-coder, 43808 MiB) came back when the
fine-tune finished, so GPU2 now holds 3 servers — teacher :8013 (38058 MiB) + :8081 (43808) + RAG
(12570) = 94458/97887 MiB (96.5%), 2792 MiB free. All 4 seats health 200. Stable: vllm
pre-allocates its KV cache at startup (memory is fixed, no growth under load), but the OS margin
is thin — do not add more to GPU2 without trimming a resident.

**Committed to master, NOT pushed:** `e5ae47daa` (trailer `jett-8011 (qwen3.8-27b-fp8)`). Local
master is now 33 ahead of origin/master — 32 of those are other sessions' unpushed work
(datadesign step_6/7/8, sft serialization, the :8011 garbage-guard). Pushing would push all 32,
so the fix was left local. (The prior session's teach-me commits c26e2ae9f/bf7a61a23 ARE already
in origin/master; this new fix is not yet — push it only with a PM go, or once that other work is
pushed.)

## The learning-style reframe (the core reframe — remember this)

**One line: the module adapts to *how the user learns* (the teaching form); it does NOT measure
*how much the user knows* (mastery).** The BKT mastery model was removed entirely. The user's
*behavior* is the sole signal.

- **No comprehension scoring.** No "why does X" quiz, no correct/wrong, no posterior on a test.
  The old BKT `observe`/`applyLearning` + `ConceptMastery` type are **deleted** from `policy.ts`.
- **Signal = behavior only:**
  - *Explicit picks (high weight):* the user chooses a form from the options line — (a) deeper /
    (b) intuitive / (c) example / (d) practical / (e) what's unclear. Each is a **form directive**
    (how to teach next), not a test score.
  - *Next-prompt read (low weight, non-fakeable):* if the user does NOT pick, the model reads their
    *next prompt* for how they engaged (re-probed / dove deeper / applied it / moved on) and reports
    the implied form at `weight: "implied"`. "Prompt mining" as the primary implicit signal. A clean
    topic-move = a *mild* skip (never "didn't get it").
  - *"What's unclear" is a content signal, NOT a form signal* — moves the re-teach throttle toward
    teach-more; does NOT touch the form bandit.
- **The card (per concept),** `~/.teach-me/card.json` (schema `{concepts: Record<ConceptCard>, budget}`):
  - `forms: {depth, intuitive, example, practical: {n, hits}}` — the **form bandit** (4 arms).
  - `clarify` — "what's unclear" count (content signal).
  - `engaged`, `skipped` — interruption-tolerance evidence.
  - `last` — last reception (`first | engaged | skipped | clarify | pick:{form}`).
  - `throttle` (0..1) — the **re-teach throttle**: how much teaching this topic still earns (high =
    engaged / asks more; low = saturated / keeps skipping). The gate reads it:
    `effectiveGap = gap × throttle` (new concept defaults 0.5). Fed by behavior (picks up, skips
    down, "what's unclear" up), never by a test. **Replaces BKT mastery.**
  - `budget` (global) — interruption tolerance; drained by skips, refilled by engagements; gates how
    many blocks emit per turn.
- **Form bandit** (`selectTeachForm`): exploits the best hit-rate arm once `n ≥ MIN_N_TO_DOMINATE`
  (2) and the winner is lopsided (dominant ≥ 0.7, runner-up ≤ 0.3); otherwise returns `"altitude"`
  (the default working altitude) and keeps varying.
- **Learned-style summary** (`learnedStyleSummary`): a deterministic 1–2 line template fill from the
  card (**NO LLM call**) — Line 1 the form signal, Line 2 saturation + trend + clarify clause.
- **Dynamic teacher prompt** (two DYNAMIC parts + fixed structure): (1) the **form directive** (the
  bandit's pick → a written instruction), (2) the **learned-style summary**. Fixed: a 2–3 sentence
  explanation (jargon glossed), a 1–2 line **"On your work:" synthesis** (why the core issue is true
  + one clause tying it to the user's work, no PnL claim), a citation if one exists, and **no
  trailing question** (the options line is appended by the extension, not the teacher). Block header:
  `Core Concept: {concept}`.
- **Tunable knobs (convergence speed, conservative defaults):** `MIN_N_TO_DOMINATE=2`,
  `DOMINANT_HIT_RATE=0.7`, `RUNNER_UP_HIT_RATE=0.3`, `CLEAR_PREFERENCE_TOTAL=5`,
  `SATURATION_ENGAGED=0.7`, `SATURATION_SKIPPED=0.3`, `BUDGET_STEP=0.1`. Slow-to-commit: 2 signals
  to lean a form, a lopsided winner to call it dominant, 5 for "clear preference," ≥77% skips to call
  a topic saturated. Loosen for faster adaptation, tighten for caution.
- **The adaptive loop:** card = state, user response = update, generation = the only reader. If the
  card never changes it's static; if the card changes and generation reads it, it adapts.
- **Card migration:** old `{mastery:{x:0.8}}` → `concepts.x.throttle = 0.2` (throttle = 1 − mastery)
  on read.

## Key facts settled

- **Files (git-tracked):** `.pi/extensions/teach-me/{index.ts, policy.ts, test.ts}`. Scope doc:
  `docs/teach_me_scope_v2.md` (v3 reframe section added this session).
- **Commits:** `c26e2ae9f` (learning-style reframe: policy.ts form bandit + throttle + summary;
  index.ts dynamic prompt + `record_engagement` tool + options line + migration; test.ts) +
  `bf7a61a23` (scope-doc v3 reframe section). Both pushed. Trailer
  `Agent-Print: jett-8012 (qwen3.8-27b-fp8)`.
- **Test suite:** 105 assertions, `TEACH_ME_PHASE3_PASS`. Run:
  `cd .pi/extensions/teach-me && NODE_PATH=/home/user/.pi/agent/install/releases/1.0.2/node_modules npx tsx test.ts`.
- **policy.ts exports:** types `FormArm`/`ConceptCard`/`Card`/`FormPref`/`DecisionRecord`/`FormResult`;
  constants `TEACH_THRESHOLD`/`MIN_N_TO_DOMINATE`/`DOMINANT_HIT_RATE`/`RUNNER_UP_HIT_RATE`/
  `CLEAR_PREFERENCE_TOTAL`/`SATURATION_ENGAGED`/`SATURATION_SKIPPED`/`BUDGET_STEP`; functions
  `selectForm`/`selectTeachForm`/`learnedStyleSummary`/`applyEngagement`/`updateBudget`.
- **Teacher (GPU2):** qwen3.8-27b-fp8, port **8013**, CTX 16384, UTIL 0.38, KV fp8, FlashInfer,
  MTP k=3, `VLLM_USE_V2_MODEL_RUNNER=0`, `max_tokens 1200`, **`chat_template_kwargs:
  {enable_thinking:false}`** (REQUIRED — it's a reasoning model; without it the block is empty;
  commit e5ae47daa, 2026-10-14). Dial URL
  `TEACHER_URL = $TEACH_ME_TEACHER_URL || http://127.0.0.1:8013` (index.ts:34). Log:
  `/data/agentic_trading/logs/qwen38_8013_*.log` (relaunched 2026-10-14, health 200, pid 3210589).
- **Seat map (at time of build):** 8011 (GPU0) primary; 8012 (GPU1) semantic-worker;
  8081 (GPU2) qwen-coder — **DOWN for a fine-tune** (back UP by 2026-10-14, co-resident with the
  teacher on GPU2); 8013 (GPU2) teacher (relaunched 2026-10-14, health 200). Implementation was
  routed to :8011 (qwen38-collab) since :8081/:8012 were down at the time.
- **JITI cache (load-bearing):** `rm -f /tmp/jiti/teach-me-*.mjs` after EVERY extension code change
  (a stale cache masks edits).
- **tsc binary:** `/home/user/projects/llama.cpp/tools/ui/node_modules/typescript/bin/tsc`
  (npx tsc does not resolve from the extension dir).
- **Active by default (opt-out):** `TEACH_ME_OFF=1` disables it.

## Loading scope (project-scoped, NOT user-level)

- **Project-scoped:** the extension lives at `.pi/extensions/teach-me/` (project-level), so Pi loads
  it **only for sessions with cwd = `/data/agentic_trading`** (`projectDir = join(cwd, ".pi")`,
  pi dist/migrations.js:234 — cwd-based, no walk-up). It is **not** in the user-level dir
  `~/.pi/agent/extensions/` (which holds only `pi-repetition-guard.ts` + `subagent/`). To make it load
  for *every* Pi session regardless of project, copy it into `~/.pi/agent/extensions/`.
- **Dockerized seats:**
  - `seat-pax` — mounts `/data/agentic_trading` (same path), so the extension **code is present** and
    would **load** if its Pi session is rooted there. But **teaching fails closed**: it dials
    `127.0.0.1:8013` and the container (network mode `seat-net`) gets `Connection refused` (verified)
    — the host teacher is not on the container loopback; would need `TEACH_ME_TEACHER_URL` re-pointed
    to a host-routable addr. Its card would also be **ephemeral/separate**
    (`CARD_PATH=$HOME/.teach-me/card.json` → `/root/.teach-me/card.json`, not bind-mounted).
  - `seat-fwg` — does **not** mount `/data/agentic_trading` → extension **absent** → does **not** load.
  - `model-gw` — a model gateway, not a Pi seat.
- The main research seats (8011/8012/8081) are **host vllm servers**, not containers; their Pi
  coding-agent processes run on the host, so host sessions rooted at `/data/agentic_trading` do get
  teach-me.

## Open / next

- **Autonomous triggering (the key unverified item):** the stronger nudge is in, but a **fresh `pi`
  session test** is needed to confirm the model reliably `record_decision`s + reports engagement
  without a user prompt. This is what makes it "work without intervention."
- **QUESTION MODE wiring:** the `ask_user` tool is registered but the full question flow is not wired
  yet.
- **Teacher durability:** no systemd unit — the GPU2 teacher does not survive reboots. Add a unit when
  PM wants reboot survival.
- **Review pairing:** a different-model reviewer is needed to review the code (author/reviewer ≠ same
  model); unavailable until the fine-tune releases :8081 or :8012.
- **If you want it everywhere:** (1) copy `teach-me/` into `~/.pi/agent/extensions/` (all host Pi
  sessions); (2) for seat-pax to actually teach, set `TEACH_ME_TEACHER_URL` to a host-routable addr on
  `seat-net` + a durable card mount.

## Seat note (attribution)

Commit trailers use `jett-8012` (the session's pre-compaction fingerprint). The **live** `PI_PROVIDER`
for this session reads `jett-8011` — the model endpoint was likely re-pointed mid-session during the
fine-tune. Minor attribution nuance; the commits are the record. Not force-pushed to change it.
