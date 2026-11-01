#!/usr/bin/env bash
# S18 — Sudo Enumeration
# Tactic : Privilege Escalation (TA0004)
# Technique: T1548.003 Abuse Elevation Control Mechanism: Sudo and Sudo Caching
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S18 Sudo Enumeration — ${TARGET} ==="
$SSH "sudo -l; cat /etc/sudoers 2>/dev/null; cat /etc/sudoers.d/* 2>/dev/null" && echo "[OK]" || echo "[FAIL]"
