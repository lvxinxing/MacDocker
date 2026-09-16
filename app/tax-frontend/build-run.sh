#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${TAX_FRONTEND_DIR:-/Users/paul/Documents/workspace/best-tax/tax-frontend}"
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME:-tax-frontend-app}"
CONTAINER_NAME="${CONTAINER_NAME:-tax-frontend}"
NETWORK_NAME="${NETWORK_NAME:-tax-local}"
HTTP_PORT="${HTTP_PORT:-3200}"
CONTAINER_PORT="${CONTAINER_PORT:-3200}"
API_TARGET="${API_TARGET:-http://tax-backend:48080/admin-api}"
NPM_REGISTRY="${NPM_REGISTRY:-https://registry.npmmirror.com}"
STOP_TIMEOUT_SECONDS="${STOP_TIMEOUT_SECONDS:-10}"

if [[ ! -f "${PROJECT_DIR}/package.json" ]]; then
  echo "tax-frontend project was not found: ${PROJECT_DIR}" >&2
  echo "Set TAX_FRONTEND_DIR to the tax-frontend repository root." >&2
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "npm was not found. Install Node.js 20.11+ before running this script." >&2
  exit 1
fi

cd "${PROJECT_DIR}"

echo "Using Node=$(node -v)"
echo "Using npm=$(npm -v)"
echo "Using registry=${NPM_REGISTRY}"
echo "Using API_TARGET=${API_TARGET}"

npm install --registry="${NPM_REGISTRY}"
npm run build:prod

if [[ ! -f "${PROJECT_DIR}/express-server/public/index.html" ]]; then
  echo "Frontend build output was not found: ${PROJECT_DIR}/express-server/public/index.html" >&2
  exit 1
fi

docker network create "${NETWORK_NAME}" >/dev/null 2>&1 || true

docker build \
  --platform linux/amd64 \
  -f "${DOCKER_DIR}/Dockerfile" \
  -t "${IMAGE_NAME}" \
  "${PROJECT_DIR}"

if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  echo "Stopping existing container ${CONTAINER_NAME} (timeout ${STOP_TIMEOUT_SECONDS}s)"
  docker stop -t "${STOP_TIMEOUT_SECONDS}" "${CONTAINER_NAME}" >/dev/null || true
  docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

docker run -d \
  --name "${CONTAINER_NAME}" \
  --platform linux/amd64 \
  --network "${NETWORK_NAME}" \
  --add-host=host.docker.internal:host-gateway \
  -p "${HTTP_PORT}:${CONTAINER_PORT}" \
  -e "PORT=${CONTAINER_PORT}" \
  -e "API_TARGET=${API_TARGET}" \
  -e "NODE_ENV=production" \
  "${IMAGE_NAME}"

echo "tax-frontend is starting:"
echo "  HTTP  http://localhost:${HTTP_PORT}"
echo "  health  curl -s http://localhost:${HTTP_PORT}/healthz"
echo "  API proxy  ${API_TARGET}"
