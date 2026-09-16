#!/usr/bin/env bash
# 从 tax-backend 容器探测 application-dev 里的局域网 MySQL / Redis 端口。
# 只做 ICMP + TCP，不带账号密码。
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-tax-backend}"
TAX_DEV_HOST="${TAX_DEV_HOST:-10.64.228.217}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
REDIS_PORT="${REDIS_PORT:-6379}"

if ! docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  echo "container not found: ${CONTAINER_NAME}" >&2
  exit 1
fi

echo "LAN probe from ${CONTAINER_NAME} -> ${TAX_DEV_HOST}"
echo "--- ping ---"
docker exec "${CONTAINER_NAME}" ping -c 2 -W 2 "${TAX_DEV_HOST}"
echo "--- nc ${MYSQL_PORT} ---"
docker exec "${CONTAINER_NAME}" nc -vz -w 3 "${TAX_DEV_HOST}" "${MYSQL_PORT}"
echo "--- nc ${REDIS_PORT} ---"
docker exec "${CONTAINER_NAME}" nc -vz -w 3 "${TAX_DEV_HOST}" "${REDIS_PORT}"
echo "--- telnet ${MYSQL_PORT} ---"
docker exec "${CONTAINER_NAME}" sh -c "echo quit | timeout 3 telnet '${TAX_DEV_HOST}' '${MYSQL_PORT}'" || true
echo "--- telnet ${REDIS_PORT} ---"
docker exec "${CONTAINER_NAME}" sh -c "echo quit | timeout 3 telnet '${TAX_DEV_HOST}' '${REDIS_PORT}'" || true
echo "LAN TCP probe finished"
