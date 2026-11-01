#!/usr/bin/env bash
# S05 — File System Enumeration
# Tactic : Discovery (TA0007)
# Technique: T1083 File and Directory Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S05 File System Enumeration — ${TARGET} ==="
$SSH "ls -la /; ls /home; ls /root; ls /var/www 2>/dev/null || echo 'no /var/www'" && echo "[OK]" || echo "[FAIL]"
