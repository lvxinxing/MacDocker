#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${TAX_BACKEND_DIR:-/Users/paul/Documents/workspace/best-tax/tax-backend}"
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_NAME="${IMAGE_NAME:-tax-backend-app}"
CONTAINER_NAME="${CONTAINER_NAME:-tax-backend}"
NETWORK_NAME="${NETWORK_NAME:-tax-local}"
HTTP_PORT="${HTTP_PORT:-48081}"
JPDA_PORT="${JPDA_PORT:-5012}"
FRONTEND_HTTP_PORT="${FRONTEND_HTTP_PORT:-3200}"
ADMIN_UI_URL="${ADMIN_UI_URL:-http://localhost:${FRONTEND_HTTP_PORT}}"
SETTINGS_FILE="${SETTINGS_FILE:-/Users/paul/.m2/settings.xml}"
STOP_TIMEOUT_SECONDS="${STOP_TIMEOUT_SECONDS:-30}"
JAVA_HOME_FOR_BUILD="${TAX_JAVA_HOME:-/Users/paul/Library/Java/JavaVirtualMachines/corretto-17.0.17/Contents/Home}"
SPRING_PROFILES_ACTIVE="${SPRING_PROFILES_ACTIVE:-dev}"
APOLLO_ENV="DEV"
APOLLO_META="${APOLLO_META:-http://10.45.10.46:8080,http://10.45.10.47:8080}"

detect_maven_bin() {
  if [[ -n "${TAX_MAVEN_HOME:-}" ]]; then
    echo "${TAX_MAVEN_HOME}/bin/mvn"
    return
  fi

  if command -v mvn >/dev/null 2>&1; then
    command -v mvn
    return
  fi

  echo ""
}

if [[ ! -x "${JAVA_HOME_FOR_BUILD}/bin/java" ]]; then
  echo "JDK 17 was not found: ${JAVA_HOME_FOR_BUILD}" >&2
  echo "Set TAX_JAVA_HOME to a JDK 17 home before running this script." >&2
  exit 1
fi

MAVEN_BIN="$(detect_maven_bin)"
if [[ -z "${MAVEN_BIN}" || ! -x "${MAVEN_BIN}" ]]; then
  echo "Maven was not found. Set TAX_MAVEN_HOME or install Maven 3.9+." >&2
  exit 1
fi

if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "Maven settings file was not found: ${SETTINGS_FILE}" >&2
  exit 1
fi

if [[ ! -f "${PROJECT_DIR}/pom.xml" ]]; then
  echo "tax-backend project was not found: ${PROJECT_DIR}" >&2
  echo "Set TAX_BACKEND_DIR to the tax-backend repository root." >&2
  exit 1
fi

export JAVA_HOME="${JAVA_HOME_FOR_BUILD}"
export PATH="${JAVA_HOME}/bin:${PATH}"

cd "${PROJECT_DIR}"

echo "Using JAVA_HOME=${JAVA_HOME}"
java -version
echo "Using Maven=$("${MAVEN_BIN}" -version | head -1)"
echo "Using settings=${SETTINGS_FILE}"
echo "Using profile=${SPRING_PROFILES_ACTIVE}"
if [[ "${SPRING_PROFILES_ACTIVE}" != "dev" ]]; then
  echo "ERROR: Docker 联调必须使用 SPRING_PROFILES_ACTIVE=dev，并由 Apollo DEV 提供基础设施配置。当前是 ${SPRING_PROFILES_ACTIVE}" >&2
  exit 1
fi
echo "Using admin UI=${ADMIN_UI_URL}"
echo "Using Apollo env=${APOLLO_ENV}"
if [[ -z "${APOLLO_META}" ]]; then
  echo "ERROR: APOLLO_META is required for local Docker because tax-local cannot resolve apollo.meta." >&2
  echo "Run: APOLLO_META='<DEV Meta URL>' ./build-run.sh" >&2
  exit 1
fi
echo "Using Apollo meta=provided (value hidden)"

"${MAVEN_BIN}" -pl tax-server -am clean package \
  -s "${SETTINGS_FILE}" \
  -Dmaven.test.skip=true

JAR_FILE="${PROJECT_DIR}/tax-server/target/tax-server.jar"
if [[ ! -f "${JAR_FILE}" ]]; then
  echo "JAR file was not found: ${JAR_FILE}" >&2
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
  -p "${HTTP_PORT}:48080" \
  -p "${JPDA_PORT}:5005" \
  -e "SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}" \
  -e "ENV=${APOLLO_ENV}" \
  -e "APOLLO_META=${APOLLO_META}" \
  -e "ARGS=--tax.web.admin-ui.url=${ADMIN_UI_URL} --tax.cas.server-url=${ADMIN_UI_URL} --tax.cas.success-redirect-url=${ADMIN_UI_URL} --tax.cas.failure-redirect-url=${ADMIN_UI_URL}/403" \
  "${IMAGE_NAME}"

echo "tax-backend is starting:"
echo "  HTTP  http://localhost:${HTTP_PORT}"
echo "  JPDA  localhost:${JPDA_PORT}"
echo "  health  curl -s http://localhost:${HTTP_PORT}/actuator/health"
echo "  profile ${SPRING_PROFILES_ACTIVE}"

echo "Verifying LAN ports from container (ping/nc/telnet, no credentials)"
"${DOCKER_DIR}/verify-lan.sh"

echo "Waiting for actuator health..."
for i in $(seq 1 45); do
  if curl -sf "http://localhost:${HTTP_PORT}/actuator/health" | grep -q '"status":"UP"'; then
    echo "health UP"
    break
  fi
  if ! docker container inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" | grep -q true; then
    echo "container exited; last logs:" >&2
    docker logs --tail 80 "${CONTAINER_NAME}" >&2 || true
    exit 1
  fi
  sleep 2
done
curl -s "http://localhost:${HTTP_PORT}/actuator/health" || true
echo
