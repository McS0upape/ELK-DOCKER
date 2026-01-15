#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${BASE_DIR}/docker/logs"

mkdir -p "${LOG_DIR}"

TS_SYSLOG="$(date +"%b %e %T")"
HOST="siem-host"

cat <<EOL >> "${LOG_DIR}/syslog.log"
${TS_SYSLOG} ${HOST} systemd[1]: Started Session 42 of user root.
${TS_SYSLOG} ${HOST} kernel: [ 1234.567890] eth0: link up
${TS_SYSLOG} ${HOST} CRON[12345]: (root) CMD (/usr/local/bin/backup.sh)
EOL

cat <<EOL >> "${LOG_DIR}/auth.log"
${TS_SYSLOG} ${HOST} sshd[2222]: Failed password for invalid user admin from 192.168.1.50 port 51122 ssh2
${TS_SYSLOG} ${HOST} sshd[2222]: Accepted password for root from 192.168.1.10 port 51123 ssh2
${TS_SYSLOG} ${HOST} sudo:   alice : TTY=pts/0 ; PWD=/home/alice ; USER=root ; COMMAND=/bin/cat /etc/shadow
EOL

APACHE_TS="$(date +"%d/%b/%Y:%H:%M:%S %z")"
cat <<EOL >> "${LOG_DIR}/apache_access.log"
127.0.0.1 - - [${APACHE_TS}] "GET /index.html HTTP/1.1" 200 1024 "-" "Mozilla/5.0"
10.0.0.5 - - [${APACHE_TS}] "POST /login HTTP/1.1" 401 512 "-" "curl/8.0"
203.0.113.9 - - [${APACHE_TS}] "GET /admin HTTP/1.1" 403 64 "-" "Mozilla/5.0"
EOL

cat <<EOL >> "${LOG_DIR}/app.log"
${TS_SYSLOG} ${HOST} app[9000]: INFO Service started
${TS_SYSLOG} ${HOST} app[9000]: WARN Cache miss for key user:42
${TS_SYSLOG} ${HOST} app[9000]: ERROR Database connection failed
EOL

cat <<EOL >> "${LOG_DIR}/logstash-test.log"
${TS_SYSLOG} ${HOST} logstash-test: Hello from Logstash test file
EOL

echo "Logs generated in ${LOG_DIR}"
