#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${BASE_DIR}/docker/logs"

mkdir -p "${LOG_DIR}"

TS_SYSLOG="$(date +"%b %e %T")"
APACHE_TS="$(date +"%d/%b/%Y:%H:%M:%S %z")"

machines=(
  "linux web01 10.0.10.21 corp"
  "linux db01 10.0.10.22 corp"
  "linux bastion01 192.168.50.10 lab"
  "unix solaris01 172.16.20.11 dmz"
  "macos mbp01 192.168.50.42 lab"
)

for entry in "${machines[@]}"; do
  IFS=' ' read -r os host ip net <<< "${entry}"

  syslog_file="${LOG_DIR}/${os}_${host}_${ip}_${net}_syslog.log"
  auth_file="${LOG_DIR}/${os}_${host}_${ip}_${net}_auth.log"
  app_file="${LOG_DIR}/${os}_${host}_${ip}_${net}_app.log"

  cat <<EOL >> "${syslog_file}"
${TS_SYSLOG} ${host} systemd[1]: Started Session 42 of user root.
${TS_SYSLOG} ${host} kernel: [ 1234.567890] eth0: link up
${TS_SYSLOG} ${host} CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
EOL

  cat <<EOL >> "${auth_file}"
${TS_SYSLOG} ${host} sshd[2222]: Failed password for invalid user admin from 198.51.100.23 port 51122 ssh2
${TS_SYSLOG} ${host} sshd[2222]: Accepted password for root from 203.0.113.9 port 51123 ssh2
${TS_SYSLOG} ${host} sudo:   alice : TTY=pts/0 ; PWD=/home/alice ; USER=root ; COMMAND=/bin/cat /etc/shadow
EOL

  cat <<EOL >> "${app_file}"
${TS_SYSLOG} ${host} app[9000]: INFO Service started
${TS_SYSLOG} ${host} app[9000]: WARN Cache miss for key user:42
${TS_SYSLOG} ${host} app[9000]: ERROR Database connection failed
EOL
done

apache_file="${LOG_DIR}/linux_web01_10.0.10.21_corp_apache.log"
cat <<EOL >> "${apache_file}"
127.0.0.1 - - [${APACHE_TS}] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0"
10.0.10.55 - - [${APACHE_TS}] "POST /login HTTP/1.1" 401 512 "-" "curl/8.0"
203.0.113.9 - - [${APACHE_TS}] "GET /admin HTTP/1.1" 403 64 "-" "Mozilla/5.0"
EOL

echo "Logs generated in ${LOG_DIR}"
