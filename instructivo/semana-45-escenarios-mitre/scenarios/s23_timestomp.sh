#!/usr/bin/env bash
# S23 — Timestomp
# Tactic : Defense Evasion (TA0005)
# Technique: T1070.006 Indicator Removal: Timestomp
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S23 Timestomp — ${TARGET} ==="
$SSH "touch /tmp/legit_file; stat /tmp/legit_file; touch -t 202001010000 /tmp/legit_file; stat /tmp/legit_file" && echo "[OK]" || echo "[FAIL]"
