#!/usr/bin/env bash
# S13 — Memory / Disk Credential Search
# Tactic : Credential Access (TA0006)
# Technique: T1552.001 Unsecured Credentials: Credentials In Files
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S13 Memory Credential Search — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "grep -r 'pass' /var/www/html 2>/dev/null | head -5; find /var /etc /home /tmp -name '.env' 2>/dev/null | head -5; find /var /etc /home /tmp -name 'credentials' -o -name '*.credential' 2>/dev/null | head -5; exit 0" && echo "[OK]" || echo "[FAIL]"
