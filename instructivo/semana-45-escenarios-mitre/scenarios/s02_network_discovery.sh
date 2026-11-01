#!/usr/bin/env bash
# S02 — Network Discovery
# Tactic : Discovery (TA0007)
# Techniques: T1016 System Network Configuration Discovery, T1049 System Network Connections Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S02 Network Discovery — ${TARGET} ==="
$SSH "ip a || ifconfig; ip route; ss -tulnp || netstat -tulnp" && echo "[OK]" || echo "[FAIL]"
