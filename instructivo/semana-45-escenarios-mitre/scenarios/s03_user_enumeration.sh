#!/usr/bin/env bash
# S03 — User Enumeration
# Tactic : Discovery (TA0007)
# Technique: T1087.001 Account Discovery: Local Account
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S03 User Enumeration — ${TARGET} ==="
$SSH "cat /etc/passwd; w; who; last" && echo "[OK]" || echo "[FAIL]"
