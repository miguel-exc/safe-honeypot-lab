#!/usr/bin/env bash
# S07 — Software Inventory
# Tactic : Discovery (TA0007)
# Technique: T1518.001 Software Discovery: Security Software Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S07 Software Inventory — ${TARGET} ==="
$SSH "dpkg -l 2>/dev/null | head -30; which python3 curl wget nc ncat; pip3 list 2>/dev/null | head -10" && echo "[OK]" || echo "[FAIL]"
