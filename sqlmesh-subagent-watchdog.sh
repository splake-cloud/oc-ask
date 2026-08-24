#!/bin/bash
# Watchdog: monitors opencode-server cgroup for subagents exceeding 14G RSS.
# When a process exceeds the limit, it is killed to prevent host OOM.
# This is a soft cap — the hard cap is MemoryMax=8G on the cgroup itself.
# The 14G limit is per-process, not per-cgroup.

CGROUP_PATH="/sys/fs/cgroup/user.slice/user-1000.slice/user@1000.service/app.slice/opencode-server.service"
PID_LIMIT_KB=14336000  # 14GB in KB
CHECK_INTERVAL=5  # seconds

while true; do
    for pid in $(cat "$CGROUP_PATH/cgroup.procs" 2>/dev/null); do
        # Skip the main server process (PID 2047894)
        if [ "$pid" = "2047894" ]; then
            continue
        fi
        
        # Get RSS in KB
        rss=$(cat "/proc/$pid/status" 2>/dev/null | grep VmRSS | awk '{print $2}')
        if [ -z "$rss" ]; then
            continue
        fi
        
        if [ "$rss" -gt "$PID_LIMIT_KB" ]; then
            echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) KILL pid=$pid rss=${rss}KB limit=${PID_LIMIT_KB}KB" >> /home/user/logs/sqlmesh_subagent_watchdog.log
            kill -9 "$pid" 2>/dev/null
        fi
    done
    sleep "$CHECK_INTERVAL"
done
