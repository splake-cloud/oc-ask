# 2026-09-27 — fwg hard-sandboxed Pi seat (built, live, verified)

## Objective

PM: add a "seat" to the workstation for a specific user (`frontline-wg`,
unrelated workstream): the user can log in, drop into their own workdir, have
access to the Pi models, be constrained to that directory, maintain memory
across sessions (so responses improve as the model learns the user), and have
NO RAG. Requirement escalated mid-build to a **hard sandbox** — no workstation
data outside the sandbox, no system-information access. Additional rulings:
seat defaults to **8012**; the Pi TUI footer must show **only the provider
prefix** (e.g. `(jett-8012)`), never the model name/thinking level; a
user-facing login README (starting with passphrase SSH key creation on the
user's own computer) and a RAG card for building future sandboxed seats.

## Architecture (what "seat" is on this station now)

```
ssh key-only → sshd Match User frontline-wg (ForceCommand)
  → /usr/local/sbin/seat-fwg-attach (root-owned, NO args, NOPASSWD sudo line)
    → docker exec -it seat-fwg → tmux new-session -A -s main bash
      container fwg-seat image:
        /workspace      = /data/seat/fwg/ws        (700 frontline-wg, rw, ONLY host data)
        /root/.pi/agent = /data/seat/fwg/piagent   (pi sessions + memory files)
        net: seat-net 172.29.0.0/16 (internet egress; tailnet/loopback-svc blocked)
model-gw (ONE shared container, host-net): socat 8011/8012/8081
        172.29.0.1 → 127.0.0.1 (vllm, unauthenticated on host loopback)
```

Confines the HUMAN too, not just the model: the login shell IS the sandbox.

## Load-bearing facts (each cost real debugging time)

1. **Host firewall blocks container→bridge-gateway-IP and container→container**
   on docker bridges (verified with a local control listener); container→internet
   egress works. Valid fix: `iptables -I INPUT -s 172.29.0.0/16 -d 172.29.0.1
   -p tcp -m multiport --dports 8011,8012,8081 -j ACCEPT`. `MASQUERADE` with a
   destination inside the source subnet is KERNEL-INVALID (Invalid argument).
   Tailnet egress blocked by `FORWARD -s 172.29.0.0/16 -d 100.64.0.0/10 -j DROP`.
   Rules are NOT persistent (netfilter-persistent absent) — re-run
   fwg-seat-install.sh after reboots.
2. **Pi's fresh-session default model = FIRST provider in models.json.**
   `PI_PROVIDER`/`PI_MODEL` env are ignored for the default (verified: fresh
   session recorded jett-8011 despite env=8012). Seat default = models.json
   ORDER; `set-default-model-8012.py` reorders idempotently (in install script).
3. **tmux 3.3a (bookworm) headless bug**: pane input stops delivering when the
   server runs without an attached client → image builds tmux 3.5a from source
   (needs bison). Server is created by the first attached login
   (`new-session -A`); container PID1 is `tail -f /dev/null`.
4. **Docker group == root == sandbox escape** → the seat user gets a
   no-argument, root-owned sudo wrapper instead; never group membership.
5. **Footer patch** (`patch-hide-model.js`, applied at image build): hides
   model id + thinking level; the patcher FAILS THE BUILD if a future pi
   version changes the code (re-derive, don't blind-re-run). Pane-verified:
   `(jett-8012)` only.
6. 8081 upstream (qwen3.6-35b vllm) was DOWN on host loopback that day
   (pre-existing; tailnet `tailscale serve` proxy 404'd) — seat degrades
   gracefully to 8011/8012.

## Memory design (per PM: model learns the user over time)

- pi sessions persist via mounted piagent (`pi -c` resumes after restarts).
- `/workspace/notes/profile.md` — durable user context; workdir `AGENTS.md`
  carries the standing duty (read at session start; update on durable facts).
- `/workspace/notes/log.md` — append-only session log.
- Pi has no other long-term memory; these files ARE the memory.

## Artifacts

- Seat state: `/data/seat/fwg/{ws,piagent}` (700 frontline-wg)
- Build artifacts: `/home/user/seat-fwg/` — Dockerfile.seat,
  Dockerfile.gateway + gateway-entry.sh, patch-hide-model.js,
  fwg-seat-install.sh (idempotent, root, with hard model-path gate),
  set-default-model-8012.py, README-login.md
- System: /usr/local/sbin/seat-fwg-attach, /etc/sudoers.d/seat-fwg,
  /etc/ssh/sshd_config.d/90-fwg-seat.conf
- **RAG card**: `docs/model-kb/sandboxed_seat_runbook.md` — per-user checklist
  + all the facts above; registered in harvest_doctrine.py allowlist, seeded
  BOTH roots, retrieval-verified (top-4 on "how do I add a sandboxed seat for
  a new user"). **Commit 1622104b pushed** (agentic_trading).
- **User README**: `docs/model-kb/README-login.md` (version-controlled per PM
  ask; source copy /home/user/seat-fwg/README-login.md; optionally also in
  their /workspace).
- Next seat = the runbook's §2 checklist; firewall+gateway are
  subnet-scoped so NO new firewall surface is needed on seat-net.
