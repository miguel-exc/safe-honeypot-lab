#!/usr/bin/env bash
# S19 — SUID Binary Abuse
# Tactic : Privilege Escalation (TA0004)
# Technique: T1548.001 Abuse Elevation Control Mechanism: Setuid and Setgid
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S19 SUID Binary Abuse — ${TARGET} ==="
$SSH "find / -perm -4000 -user root -type f 2>/dev/null; find / -perm -u=s -type f 2>/dev/null | head -20" && echo "[OK]" || echo "[FAIL]"
