#!/usr/bin/env bash
# S01 — System Information Discovery
# Tactic : Discovery (TA0007)
# Technique: T1082 System Information Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S01 System Information Discovery — ${TARGET} ==="
$SSH "id && whoami && uname -a && hostname && uptime" && echo "[OK]" || echo "[FAIL]"
