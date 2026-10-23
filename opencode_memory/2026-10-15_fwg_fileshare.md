# fwg seat file share (point-and-click in/out) — 2026-10-15

## What was built

Browser file share for the `seat-fwg` container workdir, so the seat's human user
(point-and-click, non-CLI) can get files in and out without sftp.

- **Container**: `fwg-fileshare` (image `sigoden/dufs:latest`, `--restart unless-stopped`, network `seat-net`)
- **Mount**: `/data/seat/fwg/ws:/data:rw` (the host side of the seat's `/workspace` bind mount)
- **Port**: `-p 100.84.194.106:8465:80` — bound to the host **Tailscale IP only** (tailnet-scoped;
  not reachable from LAN/internet)
- **Flags**: `--allow-upload` only. Upload/mkdir/rename allowed, **delete NOT enabled** (DELETE → 403).
- **Auth**: HTTP basic, user `fwg`, 20-char password generated with `openssl rand`.
  Credentials stored at `/tmp/.fwg-fileshare-creds` (600, root… see caveat) — **show to the user once**.

## How the user uses it

- Browser: `http://project-jett.taila0104a.ts.net:8465/` (or `http://100.84.194.106:8465/`) →
  login `fwg` / password → click files to download; Upload button in the UI.
- Windows Explorer: map a network drive to `http://project-jett.taila0104a.ts.net:8465`
  (WebDAV; dufs serves both browser UI and WebDAV).

## Why this design

- Seat ssh accounts are attach-only: `Match User frontline-wg` → `ForceCommand seat-fwg-attach`
  (`docker exec … tmux`), which hijacks the sftp subsystem too → sftp as a seat user can never work.
- Container itself has no ssh/sftp daemon, no exposed ports (docker bridge `seat-net`).
- First candidate `filebrowser/filebrowser` was **pulled then rejected**: project archived
  2026-09-01 with known unfixed security advisories (printed in its own startup notice).
  dufs chosen instead: active, single binary, per-operation permission flags.
- `tailscale serve` was NOT used: requires root operator (`serve config denied` for `user`,
  sudo needs password) and serve isn't enabled on the tailnet. Direct port bind to the
  Tailscale IP gives the same tailnet-only boundary without sudo.

## Safety backstops

- Web UI cannot delete. The seat's own auto-commit loop (`/workspace/.fwg-git/commit-loop.sh`,
  commits `/fwg` = `/data/seat/fwg` every 5 min, daily GitHub sweep via
  `/home/user/seat-fwg/fwg-git-sync.sh`) version-covers the workdir regardless.
- Everything in the workdir is visible (it's the whole `/workspace`), not a subdirectory.

## Verified (2026-10-15, from host seat)

- Download via tailnet IP: 200, md5 `6a6b2346…` == container source (frontdoor.md)
- Upload via tailnet IP (PUT): 201, file confirmed in `/workspace` via `docker exec seat-fwg`
- DELETE via tailnet IP: **403** (blocked), file intact
- No-auth request: 401
- Test file cleaned up after verification

## Open / caveats

- If the host's Tailscale IP ever changes, the `-p 100.84.194.106:…` binding must be recreated
  (`docker rm -f fwg-fileshare` + re-run with new IP; `tailscale ip -4` shows current).
- Password also visible in the container's command line (`docker inspect fwg-fileshare`) —
  anyone with docker access on the host is root-equivalent anyway.
- `filebrowser` image left local (pulled during the rejected attempt); harmless, removable.
- Earlier in this thread: 15 files copied from `seat-fwg:/workspace/projects/fwg-coaching/`
  → `/data/agentic_trading/fwg/` via `docker cp` (md5-verified identical).
