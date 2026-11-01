#!/usr/bin/env bash
# S06 — Service Enumeration
# Tactic : Discovery (TA0007)
# Technique: T1007 System Service Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S06 Service Enumeration — ${TARGET} ==="
$SSH "systemctl list-units --type=service --state=running 2>/dev/null || service --status-all 2>/dev/null; cat /etc/services | head -30" && echo "[OK]" || echo "[FAIL]"
