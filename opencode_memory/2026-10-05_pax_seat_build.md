# pax seat build — hard-sandboxed Pi research seat for paxton, Mode B full data pool (2026-10-05)

**What was built.** Second sandboxed pi seat on the box (pattern: the 2026-09-27 fwg
build). User `paxton` (markets & trading researcher, remote — US East Coast),
slug `pax`, container `seat-pax`. Shares the `fwg-seat` image (pi 0.87.1 +
footer patch → TUI shows only `jett-<port>`), `model-gw`, and `seat-net` —
no new firewall surface. Model binding: **8011 primary** (first in
models.json), 8012 + 8081 available; 8081 is a SOFT check in the installer
(known-flaky upstream; warning, never fatal).

**Data access — PM ruling 2026-10-05: "all data", Mode B.** Deliberate
deviation from the runbook's "never all of /data/parquet" (recorded dated in
the runbook §11):
- `/data/parquet` bound ro **at the same absolute path** (184 top-level
  entries, ~560 GB) — same-path is load-bearing: the snapshot DBs' views
  reference /data/parquet and only resolve because of it.
- DuckDB NOT live-mounted: `pax-data-snap.sh` (host-user crontab, daily
  06:00 UTC — cadence changeable) copies `/data/warehouse/warehouse.duckdb`
  (~15 GB) + `/data/agentic_trading/research.duckdb` (~0.65 GB) into
  `/home/user/seat-pax/snaps/` — WAL-quiesce wait, post-copy validation
  (read-only catalog query), atomic .tmp→final mv, `manifest.json`
  freshness record. Mounted ro at `/data/snapshots` in the seat. Copies live
  OUTSIDE /data/seat → no host-write exception into seat state.
- This duckdb build (1.5.5 "Variegata") has NO backup/EXPORT DATABASE
  statement (CLI or python) — validated raw-copy is the mechanism; a main
  file without its WAL is a valid DB as of last checkpoint (stale, never
  corrupt).
- Bound-scan discipline (filter on partition/date before aggregating;
  sample first) written into the seat's `/workspace/AGENTS.md`.

**Key facts / locations.**
- Canonical seat doctrine: `docs/model-kb/sandboxed_seat_runbook.md` — now
  carries the pax §11 ruling, §7 pax file map, §8 drift (two seats).
- Build files: `/home/user/seat-pax/{pax-seat-install.sh (idempotent,
  root-run, chroot-safe), pax-data-snap.sh, snaps/}`.
- Seat state: `/data/seat/pax/{ws,piagent}` — 700 paxton, group `seat-pax`
  (setgid 2770/640; operator `user` in the group — takes effect on the
  operator's next login).
- Host plumbing: `/usr/local/sbin/seat-pax-attach`, `/etc/ssh/sshd_config.d/
  90-pax-seat.conf` (ForceCommand), `/etc/sudoers.d/seat-pax` (one NOPASSWD
  line).
- ws template: fresh paxton AGENTS.md (identity + Mode B data section +
  env + delegation + rebuild scripts), copied portable fwg assets
  (.venv 1.1G, setup-{web-browser,tmux,locale}.sh, tmux.conf,
  source_attribution.md, footer self-heal patch+extension,
  reasoning-loop-block extension, explore-8081 agent, dark-0871 theme).
  EXCLUDED as fwg-specific: pi-research stack + BYOK search keys, review-agent
  (podcast), knowledge-store, git-sync.
- Gates verified (verify-run receipts in /data/agentic_trading/verify/
  pax-gate-* + pax-smoke-pi): 3 model ports reachable from seat-net; tailnet
  blocked; RAG unreachable; internet OK; exactly 4 mounts; parquet ro
  (write refused); workspace rw; both snapshots open + 64 tables; venv core
  imports inside seat; firewall rules live; `pi -p` smoke = PAXOK.

**RAG granted (2026-10-06).** The seat now reaches the workstation RAG:
DNAT `172.29.0.0/16 → 172.29.0.1:8765 → 127.0.0.1:8765` (nat PREROUTING) +
INPUT accept for the DNATed flow + `route_localnet=1` (persisted,
`/etc/sysctl.d/99-seat-rag.conf`). All three wired into
`pax-seat-install.sh` (idempotent guards + verify-phase RAG gate); the
seat's `/workspace/AGENTS.md` gained a RAG section (endpoint, JSON search
shape, 28 collections, prior-not-filter discipline); its stale "no RAG
reachable" claim was replaced. Traps hit: (a) DNAT to a loopback destination
requires `route_localnet=1` or the kernel silently drops it; (b) a chroot
run WITHOUT `--network=host` reads/writes the container's netns, not the
host's — an iptables rule "added" there vanishes with the container (vantage
trap, same family as the observability doctrine). Scope: subnet-scoped, so
the fwg seat can also read the RAG — accepted (read-only service).
NOTE: the sysctl flipped 0→1 at an unobserved moment mid-session (unknown
actor); persistence covers it either way.

**Root-mutation vantage (this box).** Operator `user` has NO passwordless
sudo but IS in the docker group → root ops ran as
`docker run --rm --network=host --pid=host --cap-add=NET_ADMIN -v /:/host
fwg-seat chroot /host <cmd>` (chroot sees the HOST userland + netns + PID ns
+ docker socket). Remember: iptables checks need BOTH `--network=host` and
`--cap-add=NET_ADMIN`, or you read an empty container netns (false
"rules missing" — vantage trap).

**Research stack ported (2026-10-06).** The fwg seat's patched research
stack was ported byte-identical into pax's seat: pi-research 1.7.8 full
patch set (npm/ 2.4G + patches/ reapply machinery + backups/ +
.pi-research knowledge_db), donsetch 4.3.6 web layer (Chromium installed,
no_sandbox toml, `doctor --deep` all green), `tvly-social` (ws/bin),
repetition guard (ported in fwg's exact state: present but `.disabled`),
BYOK research config (container-local, durable backup at
`piagent/.research-config.env.bak`), and **pi 1.0.0** (fwg runs 1.0.0 in
its container overlay; the image ships 0.87.1 and the patched package
requires ≥0.99.0 — pax now matches). pax's piagent settings.json gained
the `npm:@lincoln504/pi-research@1.7.8` package entry (it only had
donsetch — the research tool was registered but not loaded). Verified:
byte-parity diff clean, research tool loads (control test: fwg yes / pax
yes), tvly-social runs, donsetch browser launches in ~500 ms. Restore:
`ws/bin/setup-research-stack.sh` (idempotent, tested) + seat AGENTS.md
"Research stack" section. Traps: `docker exec <c> python - <<EOF` does NOT
pass stdin (needs -i or a mounted script file — caused two silent no-op
patches); a running donsetch daemon holds its binary (Text file busy) —
kill before re-copying; npm package copy requires the daemon stopped
first.

**Build gaps (operator-reported 2026-10-06; verified by inspection).**
1. **Process gap — RAG access was never asked at build time.** The operator
   wanted RAG access; it only landed via the 2026-10-06 discovery session
   (DNAT + route_localnet, above). Lesson: seat build checklists must ask
   "RAG access: yes/no" up front — it is a firewall-surface decision, not an
   afterthought. (Runbook §11 already records the grant; the question itself
   is still missing from the build procedure.)
2. **Build ran rebuild steps 3–5, skipped 1–2** (locale, tmux — the two that
   fix the pi frozen-spinner and tmux scroll problems). Steps 1–2 live in the
   CONTAINER layer (`/root/.bashrc` UTF-8 exports, `/root/.tmux.conf` symlink)
   → a container replacement drops them. fwg has a single
   `/workspace/bin/restore-after-rebuild.sh` that re-runs every `setup-*.sh`;
   **pax had none → parity script dispatched** (this card's 2026-10-06 fix).
   Verified live state (docker exec seat-pax): steps 1–2 were applied ad hoc
   during the 2026-10-06 session (`/root/.bashrc` exports ts 11:12,
   `/root/.tmux.conf` symlink ts 11:06) but NOT at build time. The running
   tmux server (started 10-06 01:46, before the fix) still carries POSIX env
   → active panes still show the frozen spinner until the server/panes are
   recreated (needs GO — it kills the live session). Note: the interactive
   seat runs as **root** inside the container (HOME=/root; `/home/paxton`
   does NOT exist in-container — it is the host ssh anchor only). Latent
   porting artifact: pax's `setup-locale.sh` is fwg's unmodified — it targets
   `/root/.bashrc` + `/home/fwg-admin/.bashrc` (dead on pax); `/root/.bashrc`
   happens to be the right target, and the image ships a `/root/.bashrc`, so
   risk is low. **Fixed 2026-10-06** (dead line deleted, header corrected —
   verify/ pax-locale-*).

**Build gaps (operator-reported, verified 2026-10-06 by docker-exec inspection).**
1. **Process gap: RAG access was never a question at build time.** The operator
   wanted it; it landed only via the 2026-10-06 discovery session (DNAT +
   route_localnet, above). Lesson: a seat build must ASK "RAG access: yes/no"
   up front — it is a firewall-surface decision, not an afterthought. Runbook
   §11 records the grant but the build checklist still lacks the question
   (NOTES — runbook edit pending go).
2. **Build ran rebuild steps 3–5, skipped 1–2** (locale, tmux) — exactly the
   two that fix pi's frozen spinner (POSIX locale) and the tmux scroll
   problem. Both live in the CONTAINER layer, so any container replacement
   drops them. fwg has a single `/workspace/bin/restore-after-rebuild.sh`
   (runs every setup-*.sh, idempotent, one failure doesn't stop the rest);
   pax had none → parity script DELIVERED 2026-10-06 (qwen-coder BUILD
   envelope; receipts verify/ pax-restore-*, sha 01e8aa56…, mode 755,
   structure = fwg's: locale, tmux, research-stack, login-silence +
   conditional web-browser). pax AGENTS.md "After a container
   replacement" now points at it (line 295, one-line EDIT, receipt
   verify/ pax-agentsmd-diff.20261006T112432Z.txt).
   Verified live state at report time: interactive seat runs as **root** in-
   container (HOME=/root; `/home/paxton` is the HOST ssh anchor only, absent
   in-container; tmux socket /tmp/tmux-0). `/root/.bashrc` gained the UTF-8
   exports Oct 6 11:12 and `/root/.tmux.conf → /workspace/config/tmux.conf`
   Oct 6 11:06 — i.e. steps 1–2 were applied ad hoc during the 10-06 session,
   not at build. The RUNNING tmux server started Oct 6 01:46 (before those)
   still carries POSIX env → active panes keep the frozen spinner until the
   server is restarted / panes recreated (operator go — kills live session).
   Latent: pax's setup-locale.sh is an unadapted fwg port — targets
   `/root/.bashrc` + `/home/fwg-admin/.bashrc` (dead on pax); `/root/.bashrc`
   happens to be the right target, and its `ensure()` skips missing files, so
   a fresh container without /root/.bashrc would get nothing (fwg-seat image
   ships one — low risk). **Fixed 2026-10-06**: dead line deleted, header now
   reads "interactive user (root)" (verify/ pax-locale-*, owner/mode
   preserved).

**Open / next.**
1. ~~paxton's ed25519 pubkey PENDING~~ — RESOLVED 2026-10-06: key appended
   to `/home/paxton/.ssh/authorized_keys` (600 paxton), login path
   end-to-end verified from host loopback (auth → ForceCommand → sudo →
   docker exec → tmux `main` inside seat-pax; test key removed after).
   **Build bug caught by that test**: the installer's sshd heredoc dropped
   the `sudo` from the ForceCommand that live fwg carries — first login
   would have died in the attach wrapper with docker-socket permission
   denied. Fixed in pax live conf + pax installer + runbook §2 step 3;
   the fwg installer template still carries the latent bug (re-running it
   would strip fwg's sudo) — noted, not touched (separate go).
2. iptables rules non-persistent across reboot → re-run
   `pax-seat-install.sh` (idempotent) after reboots (same as fwg).
3. Optional add-ons (not built — separate ruling if wanted): pi-research
   stack (needs paxton's BYOK search keys), git-sync mirror of seat state
   (fwg has one for github.com/splake-cloud), jett-ai alias points at 8011
   (already staged at ws/bin/jett-ai).
4. First scheduled snapshot runs next 06:00 UTC; a valid initial snapshot
   was produced at build time (manifest ts 2026-10-05T19:41Z).
