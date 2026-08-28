# Repo cleanup: the opencode_memory fork, and the 4.70 GB that made master unpushable

One session, 2026-08-28, PM-directed throughout. Two problems that turned out to be the same
problem — things landing in git that were never meant to be there, and nobody noticing because
the guard rails were correct but inert.

## 1. opencode_memory had forked in two

**Origin: 2026-08-27**, agentic_trading commit `bcb54104`. A seat working with cwd
`/data/agentic_trading` resolved the memory path **relative to its own cwd** instead of the
`~/oc-ask/opencode_memory/` that `AGENTS.md` names, and the research commits swept the resulting
directory into the project repo. It was **bidirectional, not a stale copy**: 29 cards only in
`~/oc-ask`, **8 only in `/data`** — including `2026-08-27_iron_fly_100w_economic_baseline.md`, the
CANONICAL frozen baseline other studies cite. Both `INDEX.md` files differed, so "reorient me"
answered differently depending on which path the session landed in.

**Resolved:** 8 orphans folded into `~/oc-ask` byte-identical (sha256 per file, `372055c`); six of
them already had INDEX rows here pointing at files this repo did not have, so those broken links
now resolve. `/data/agentic_trading/opencode_memory` is a **symlink** to this directory
(agentic_trading `4f2512a9`, then on master as `b9b3e17f`). That removes the *cause* — relative
resolution from the project root now lands in the canonical store — not just the symptom.

## 2. master carried 4.70 GB and could not be pushed

10 blobs over GitHub's 100 MB **hard** limit: four 621 MB `research.duckdb` copies (one live, three
`.bak.*-consolidate`), two vendored `node_modules` binaries (codex 273 MB, claude 233 MB), four
large parquet. Introduced largely by catch-all `misc:` commits (`34519b24`, `00a19d9e`).

**The reframe that made it tractable: the blobs were only in UNPUSHED commits.** A push sends only
objects reachable from the pushed ref, so master never needed the objects *purged* — only its
commits needed to stop referencing them. That turns "rewrite published history" into "rewrite 23
commits nobody has seen." Result: **4.70 GB -> 531 MB**, a plain fast-forward push, no `--force`.

**Scoping is the whole risk.** `git filter-repo` defaults to ALL refs and this repo has ~40
branches, many pushed. Used `git filter-branch --index-filter` with an explicit
`origin/master..master` range instead, run from a **scratch worktree** (filter-branch refuses on a
dirty tree, and the project tree had 82 dirty paths throughout).

## 3. The reconstructibility check — the reusable part

**A history rewrite does not touch the working tree.** Files stay on disk, they just become
untracked. So the ONLY data-loss vector is a *git-only version*: a version in a commit that no
longer exists on disk. Two checks answer it for a removal set of any size:

1. `git diff --name-only <ref> -- <removal paths>` — which files' disk copy differs from the tip.
2. Count distinct blob SHAs per path across the range — catches intermediate versions.

Across 22,104 files, **exactly one** was git-only: `research.duckdb`, committed `cd4a38b3` vs live
`b2843ba1`. **Both are 651,177,984 bytes** — identical size, different content, because DuckDB
rewrites pages in place. A size check would have missed it; only the hash caught it. Extracted with
`git cat-file blob` and kept at `/data/agentic_trading/research.duckdb.bak.20260827T092722-git00a19d9e`
(gitignored by the existing `research.duckdb.bak.*` rule). After that the rewrite was lossless *by
construction*.

## 4. THE NEAR-MISS: a directory-scoped removal swallowed the recovery recipe

The removal set named `catalog/base_tables_export` — the whole directory. It held 24 parquet **and
two small files that should never have gone**: `manifest.json` (20 KB) and
`restore_base_tables.sql` (12 KB). The SQL opens: *"Restore the base tables from Parquet... for
rebuilding into a NEW database file after a loss"*, casting every column back to its recorded source
type (required, not cosmetic — fixed-size arrays read back from parquet as lists).

**That is the exact inversion of this project's rule: the recipe is the recovery control, the bytes
are disposable.** Removed the recipe, kept nothing. Restored byte-identical in `cc6fdefa`; no
rewrite needed since they are small.

**The correct scope was sitting in `.gitignore` all along: `catalog/base_tables_export/*.parquet`.**
When choosing what to strip from history, take the scope the ignore rules already state — they
encode a decision someone made deliberately. Directory-wide is a guess.

## 5. Why the ignore rules were inert

`.gitignore` **never applies to files already tracked**. `research.duckdb`, `.external/`, and
`catalog/base_tables_export/*.parquet` were ALL already ignored and were committed anyway (201
tracked `.parquet` on master). That asymmetry is why the bloat kept recurring, and why a rewrite
must be paired with `git rm --cached` or the rules stay decorative. `node_modules` was the one
genuine gap — now `node_modules/` in `.gitignore` (`581f491f`), verified to match at every depth.
Note `outputs/*.parquet` is **deliberately NOT ignored** (small ones tracked on purpose), so the
strip there was file-specific.

## 6. Two traps that cost real time

* **`git gc` reclaimed nothing (4.5G -> 4.4G) because MY OWN safety snapshot pinned everything.**
  `git stash create` writes a commit whose tree is the full tracked state — so the snapshot held
  the entire pre-rewrite tree *plus a fresh 621 MB copy of the live database*: **22,389 blobs,
  5.32 GB pinned by one tag.** Fix: re-mint it *after* the swap, when the big files are untracked —
  same 28 files, **16.5 MB** (`wip-snapshot-20260828b` = `5aa27635`). Then 4.5G -> **817M**.
  Also expire reflogs (`git reflog expire --expire=now --expire-unreachable=now --all`) or gc
  prunes nothing.
* **`git cat-file --batch-check` needs `%(rest)`.** Feeding `git rev-list --objects` output
  (`<sha> <path>`) without `%(rest)` in the format silently produces WRONG totals — reported
  "0.00 GB" twice for ranges that actually held 4.70 GB and 5.32 GB. Any size number from that
  pipe without `%(rest)` is untrustworthy.

## 7. Technique: rewriting a branch that is checked out and dirty

The project tree was on `iron-fly-economic-baseline` with 28 modified + 143 untracked files the
whole time. Never stashed, never checked out, never written to:

1. Copy the branch (`git branch <copy> <branch>`), work only on the copy.
2. Filter / rebase the copy in a **scratch worktree**.
3. Verify losslessly, then swap with **`git reset --mixed <copy>`** from the project tree — moves
   the branch ref and re-syncs the index, and does **not** touch the working tree. Requires nothing
   staged (was true here).
4. After the swap, files whose working copy is stale relative to the new HEAD show as modified —
   check they are not among the PM's own edits before `git checkout --` them (`.gitignore` was).

**Losslessness proof used at each step:** tree-diff old ref vs new and assert **zero** differing
paths outside the intended removal set. Master: 22,104 differing, 0 outside. Branch: same. Rebase:
only 3 paths differed, exactly what master adds.

## 8. The rebase: 33 commits -> 6

`iron-fly-economic-baseline` rebased onto the cleaned master. Git auto-skipped **23** commits as
already-applied (patch-id matched — the branch was a rebased copy of master's work); **4** more were
memory-only commits whose cards now live here (verified all 10 present in `~/oc-ask` BEFORE dropping
any). The 6 survivors are real work: baseline manifest, V0 gate + L1-D/L1-E, sqlmesh D1 gate, and
three opencode temperature-passthrough commits. Conflicts were all `opencode_memory` file/directory
collisions against the symlink; two of them also carried real files (17 and 5) and were **resolved,
not skipped**. Pushed: 6 commits, **28 blobs, 0.5 MB** — the same branch that was 4.70 GB.

## Final state

| ref | | |
|---|---|---|
| `origin/master` (market_data) | `cc6fdefa` | 531 MB, recovery recipe restored, node_modules ignored |
| `origin/iron-fly-economic-baseline` | `13a8609c` | 6 commits, based on master |
| `origin/master` (oc-ask) | `73d1c41` | 38 cards, index integrity verified both directions |
| `.git` on disk | 817M | was 4.5G |

**Irreversible:** pre-rewrite history was never pushed anywhere and is now gone from this machine.
Everything of value was verified preserved first — duckdb snapshot on disk, memory cards pushed to
oc-ask, recovery recipe restored on master, cleaned master pushed off-machine to GitHub.

## Open

* `outputs/fly_paths_nearest{5,25}.parquet` (143 / 142 MB) are untracked and **not** ignored, per the
  deliberate `outputs/*.parquet` policy. Harmless — the `scripts/hooks/pre-commit` oversized-blob
  guard blocks anything over 100 MB at commit time — but they sit in `git status` as noise.
* 13 small `node_modules` files stay tracked (pyright, json5); the new rule cannot untrack them.
* 201 tracked `.parquet` remain on master, ignored-but-tracked. Same inert-rule class as above.
