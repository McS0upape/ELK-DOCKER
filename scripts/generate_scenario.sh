#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${BASE_DIR}/docker/logs"

mkdir -p "${LOG_DIR}"

HOST="linux_bastion01"
TS_SYSLOG="$(date +"%b %e %T")"
SRC_IP="203.0.113.99"

# Brute force (multiple failed SSH)
for i in $(seq 1 8); do
  echo "${TS_SYSLOG} ${HOST} sshd[1234]: Failed password for invalid user admin from ${SRC_IP} port $((50000 + i)) ssh2" >> "${LOG_DIR}/auth.log"
done

# Successful login after brute force
echo "${TS_SYSLOG} ${HOST} sshd[1234]: Accepted password for admin from ${SRC_IP} port 51000 ssh2" >> "${LOG_DIR}/auth.log"

# Privilege escalation via sudo
echo "${TS_SYSLOG} ${HOST} sudo:   admin : TTY=pts/0 ; PWD=/home/admin ; USER=root ; COMMAND=/bin/cat /etc/shadow" >> "${LOG_DIR}/auth.log"

# Optional app error after escalation
echo "${TS_SYSLOG} ${HOST} app[9000]: ERROR Unauthorized access to /etc/shadow detected" >> "${LOG_DIR}/app.log"

echo "Scenario logs appended to ${LOG_DIR}/auth.log and ${LOG_DIR}/app.log"
