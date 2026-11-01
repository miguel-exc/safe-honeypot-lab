#!/usr/bin/env bash
# S08 — Environment & Configuration
# Tactic : Discovery (TA0007)
# Technique: T1082 System Information Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S08 Environment & Config — ${TARGET} ==="
$SSH "env; cat /etc/os-release; cat /proc/version; df -h; free -m" && echo "[OK]" || echo "[FAIL]"
