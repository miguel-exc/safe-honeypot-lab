#!/usr/bin/env bash
# S04 — Process Listing
# Tactic : Discovery (TA0007)
# Technique: T1057 Process Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S04 Process Listing — ${TARGET} ==="
$SSH "ps aux; top -b -n1 | head -20" && echo "[OK]" || echo "[FAIL]"
