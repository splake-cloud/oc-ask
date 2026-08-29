# 2026-08-29 — IV substrate reorg into `studies/iv_weekly_substrate/` + RAG organization card made retrievable

## What was done

1. **IV weekly substrate reorganized into its own study folder** (PM call: "very different than
   iron fly, own folder") per the file-placement process card
   (`.ai/research_profiles/study_and_infrastructure_artifact_hierarchy.md`, RAG collection
   `study_infra`).
2. **The card itself was fixed** so future sessions can find it, and re-indexed into both RAG
   roots.

## The process card (what governs file placement)

- Source: `.ai/research_profiles/study_and_infrastructure_artifact_hierarchy.md`; RAG well
  `study_infra`; built by `scripts/rag_verifier/build_study_infra.py`.
- Study shape: `studies/<name>/{idea.md, specs/, scripts/, outputs/, verify/, receipts/}`.
- Shared code stays canonical: models → `warehouse/models/`, shared tests → `tests/` — they do
  NOT move into a study folder.
- **New carve-out added (PM decision):** `verify-run` deposits transcripts to repo-root
  `verify/` (tool owns the path); do not move them. Instead the study keeps a single
  navigation note at `studies/<name>/verify/navigation.md` = core idea + roadmap to every
  artifact.

## New study layout (all paths verified to resolve)

```
studies/iv_weekly_substrate/
├── idea.md                  (written this session; points at navigation.md)
├── specs/                   (4 files moved from .ai/inbox/)
├── receipts/                (5 files moved from .ai/packets/iv_weekly_percentile/, dir removed)
└── verify/navigation.md     (THE single entry point: core idea + full roadmap)
```

- Models (`warehouse/models/iv_weekly_{state_daily.sql,percentile.py}`) and KASA tests
  (`tests/test_warehouse_iv_weekly_*.py`) **not moved** — canonical shared locations.
- M2 model's docstring references specs by filename, not path → no byte change → no SQLMesh
  fingerprint change.
- ⚠ **Path change vs the M2-complete card (same day):** specs are NO LONGER in `.ai/inbox/` and
  the packet dir is gone. Current home: `studies/iv_weekly_substrate/specs/` + `receipts/`.

## RAG card update — procedure + result

- **Why `--force` was required:** `study_infra_fingerprint()` = `_authored_fp("study_infra_v1",
  "build_study_infra.py")` — hashes the BUILDER SOURCE ONLY, not the card. A card edit is
  invisible to a plain `scan-stage`.
- Steps (RAG.md §0.5 / Checklist H):
  1. `scan-stage --groups study_infra --force` → 8 cards staged (was 7) to the FULL root
     (full root owns the staged corpus; small root's staged/ is vestigial).
  2. `seed-pending --root small --groups study_infra` (GPU, 0.6B, 6 s).
  3. `seed-pending --root full --groups study_infra --device cpu` (PM call: large on CPU; 8
     cards → 11 s, 8B model load dominates, not embedding).
  4. `status --root all` → full=live small=live, 8 rows each.
  5. Verified against the LIVE service, not the index.
- **No service restart needed** — reseed moves table mtime/version, drops the reader's cache.
  (Restart only needed for a NEW well, Checklist B step 8.)
- Card edits made: (a) the verify-run carve-out (above); (b) an "Agent Queries Answered"
  section with colloquial trigger lines (same pattern the well-retrieved `sqlmesh_reference`
  cards use).
- **Retrieval before → after (live service):** `file system cleanup process` miss→HIT,
  `how much file refactoring to comply` miss→HIT, `refactor files into structure` miss→HIT,
  `repo hygiene` miss→HIT, `where do the files go` HIT. Bare `cleanup` still miss — expected,
  one generic word has no discriminating power in a 23-well pool.

## Key facts for next time

- **The trap that started this:** the card's declared trigger ("before creating or moving
  study or infrastructure files") is not how a PM phrases requests — "cleanup/refactor/hygiene"
  all returned 0 cards. A card whose trigger vocabulary doesn't match the PM's vocabulary is
  invisible. Fix pattern: "Agent Queries Answered" section with the PM's actual phrasings.
- **`docs/REPO_HYGIENE_PLAN.md` (2026-08-25) is a DIFFERENT thing** — a repo-wide deletion
  checklist (192 scripts, .ai/ dirs, docs), NOT in the RAG, and NOT the placement process.
  It is largely unexecuted and 4 days stale (scripts/ top-level grew 404→576; 158 files dated
  post-25 are unclassified). If PM ever executes it, re-run its dead-file scan first.
- **verify-run evidence for the IV build stays in repo-root `verify/`** — navigate via
  `studies/iv_weekly_substrate/verify/navigation.md` (M1: `verify/m1_gate3_20260828T214546Z/`,
  M2: `verify/m2_gate3_20260829T104500Z/`).

## Committed + pushed (branch `iron-fly-economic-baseline`)

- `65203b0f` sqlmesh: IV substrate (models, tests, study folder) — 14 files
- `5eef452b` docs: artifact-hierarchy card — 1 file
- `81201293` verify: gate-0..3 transcripts + prod evidence dirs — 73 files
- `d0375a72` rag: register study_infra refresh group + fingerprint on the card — 1 file

All ~1.3 MB text/JSON/SQL/Python, zero data files (prod data lives in
`/data/warehouse/` + `/data/parquet/`, outside the repo). `dispatch_run.log`
left out (repo `*.log` gitignore).

## Open

- (none). The `--force` blind spot is now FIXED and committed (`d0375a72`):
  `study_infra_fingerprint()` hashes the card, and the `GROUPS["study_infra"]`
  registration (previously uncommitted) is in. Plain `scan-stage` now detects
  card edits; no `--force` needed going forward.
