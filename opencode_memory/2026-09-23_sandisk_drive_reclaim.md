# 2026-09-23 — SanDisk backup drive: ~720G reclaimed (PM-approved)

**Mission:** investigate removable files on the backup drive; PM then approved
removing the ~345G Tier-1 set, then the 461G GLM archive. pi seat (qwen3.8-27b-fp8).

## What was removed (all on `/media/user/Extreme SSD1`, live system untouched)

1. **184G stale home dirs** — `backup/home_user/Projects/agentic_trading/.venv-vllm`
   (82G), `llama.cpp` (40G), `llama.cpp-m3` (51G), `ik_llama.cpp` (5.7G),
   `ik_llama.cpp-86ad770f` (5.3G). All four llama.cpp clones verified
   **0 unpushed commits** (`git log --branches --not --remotes`); `git diff`
   was exFAT mode-bit noise only (0 ins/del).
2. **67G over-retention** — 4 `backup/warehouse/backup_archive/warehouse.duckdb.bak-*`
   (Aug 21–23) past the 30-day retention that live's `backup_sqlmesh_prod.sh`
   enforces; live already pruned them, the drive kept them (no `--delete`).
3. **Home trees pruned to true mirrors of live** — 12 subdirs
   (`.npm-global`, `.local/lib/python3.12`, `.local/state/opencode-local-thinking`,
   `agent-trial/venv`, `.opencode-local-thinking`, `.hf-cli`, `.venv-exl3`,
   `jdk`, `tmux-3.5`, `discord-export`, `.config/opencode`, `.claude`) via
   `rsync -rtD --delete` from live; verified 0 drive-only files after.
4. **58MB** — 2 system_config tarballs (2026-08-16) beyond the keep-4 retention.
5. **461G GLM-4.7 weights — DELETED, only copies destroyed** — drive-root
   `models/archive/` = `glm-4.7-iq4-k` (210G, 6 shards) + `glm-4.7-iq5-k`
   (251G, 7 shards), archived 2026-08-27 as "superseded GLM quants".
   Live `/data/models` holds only IQ3_KS variants; **if IQ4_K/IQ5_K are ever
   needed again, they must be re-downloaded (~461G)**. Note:
   `launch_glm_4_7_iq5_*.sh` under /data/models reference now-nonexistent paths.

## Result

Drive 78% → 60% used; 826G → ~1.5T free (3.7T exFAT volume).

## Standing items (NOT done, need PM)

- **Structural fix:** `scripts/rsync_backup_sandisk.sh` steps 2–8 are
  additive-only (only step 1 uses `--delete`), so deleted-from-live files
  re-accumulate on the drive weekly. A `--delete`/prune on step 8 is the real fix.
- **Minor script bug:** the `tarballs retained:` counter has never matched disk.
- **Known limitation (unchanged):** exFAT 1 MiB clusters — small-file trees
  (e.g. `backup/parquet`: 560G live → 679G on drive) inflate; not removable
  by file deletion, only by changing backup strategy.
- `backup/all-branches-pre-collapse-20260901.bundle` (687M) still on drive —
  pre-collapse-2026-09-01 safety bundle, branches merged to master; removable
  at PM comfort.
