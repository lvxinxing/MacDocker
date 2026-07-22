#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${BPG_PROJECT_DIR:-/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new}"
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERS_DIR="$(cd "${DOCKER_DIR}/../.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-bpg-new-vkereg-app}"
CONTAINER_NAME="${CONTAINER_NAME:-bpg-new-vkereg}"
HTTP_PORT="${HTTP_PORT:-8086}"
JPDA_PORT="${JPDA_PORT:-5011}"
SETTINGS_FILE="${SETTINGS_FILE:-/Users/paul/.m2/settings.xml}"
MAVEN_VERSION="${MAVEN_VERSION:-3.2.5}"
MAVEN_CACHE_DIR="${MAVEN_CACHE_DIR:-/private/tmp/bpg-local-maven}"
DEPLOY_DIR="${BPG_DEPLOY_DIR:-/Users/paul/Documents/java/Data/deploy}"
CONTAINER_DEPLOY_DIR="${BPG_CONTAINER_DEPLOY_DIR:-/Users/paul/Documents/java/Data/deploy}"
SOCKET_TIMEOUT_MILLIS="${SOCKET_TIMEOUT_MILLIS:-3000}"
CMB_TIMEOUT_MILLIS="${CMB_TIMEOUT_MILLIS:-3000}"
UNIONPAY_LOGIN_ON_STARTUP="${UNIONPAY_LOGIN_ON_STARTUP:-false}"

detect_java_home() {
  if [[ -n "${BPG_JAVA_HOME:-}" ]]; then
    echo "${BPG_JAVA_HOME}"
    return
  fi

  if command -v /usr/libexec/java_home >/dev/null 2>&1; then
    local java_home
    if java_home="$(/usr/libexec/java_home -v 1.8 2>/dev/null)"; then
      echo "${java_home}"
      return
    fi
  fi

  local candidate
  for candidate in \
    "/Users/paul/Library/Java/JavaVirtualMachines/corretto-1.8.0_472/Contents/Home" \
    "/Users/paul/Library/Java/JavaVirtualMachines/azul-1.8.0_472/Contents/Home"
  do
    if [[ -x "${candidate}/bin/java" ]]; then
      echo "${candidate}"
      return
    fi
  done

  echo ""
}

detect_maven_bin() {
  if [[ -n "${BPG_MAVEN_HOME:-}" ]]; then
    echo "${BPG_MAVEN_HOME}/bin/mvn"
    return
  fi

  local maven_home="${MAVEN_CACHE_DIR}/apache-maven-${MAVEN_VERSION}"
  local maven_tgz="${DOCKERS_DIR}/base/mvn/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

  if [[ ! -x "${maven_home}/bin/mvn" ]]; then
    if [[ ! -f "${maven_tgz}" ]]; then
      echo ""
      return
    fi

    mkdir -p "${MAVEN_CACHE_DIR}"
    tar -xzf "${maven_tgz}" -C "${MAVEN_CACHE_DIR}"
  fi

  echo "${maven_home}/bin/mvn"
}

check_deploy_dir() {
  if [[ ! -d "${DEPLOY_DIR}" ]]; then
    echo "Deploy directory was not found: ${DEPLOY_DIR}" >&2
    echo "Set BPG_DEPLOY_DIR to a directory that contains the runtime files mounted into the container." >&2
    exit 1
  fi

  local required_files=(
    "cert/ocb/ocb.key"
    "cert/ocb/ocb.pem"
    "cert/ocb/public-cert.pem"
  )

  local missing=()
  local deploy_file
  for deploy_file in "${required_files[@]}"; do
    if [[ ! -f "${DEPLOY_DIR}/${deploy_file}" ]]; then
      missing+=("${DEPLOY_DIR}/${deploy_file}")
    fi
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    echo "Required runtime files were not found:" >&2
    printf '  %s\n' "${missing[@]}" >&2
    echo "The bpg-new Spring context reads these files during startup; without them Tomcat deploys the WAR but the app returns 404." >&2
    echo "Expected container path: ${CONTAINER_DEPLOY_DIR}" >&2
    exit 1
  fi
}

JAVA_HOME_FOR_BUILD="$(detect_java_home)"
if [[ -z "${JAVA_HOME_FOR_BUILD}" ]]; then
  echo "JDK 8 was not found. Set BPG_JAVA_HOME to a JDK 8 home before running this script." >&2
  exit 1
fi

MAVEN_BIN="$(detect_maven_bin)"
if [[ -z "${MAVEN_BIN}" || ! -x "${MAVEN_BIN}" ]]; then
  echo "Maven ${MAVEN_VERSION} was not found. Set BPG_MAVEN_HOME before running this script." >&2
  exit 1
fi

if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "Maven settings file was not found: ${SETTINGS_FILE}" >&2
  exit 1
fi

check_deploy_dir

export JAVA_HOME="${JAVA_HOME_FOR_BUILD}"
export PATH="${JAVA_HOME}/bin:${PATH}"

cd "${PROJECT_DIR}"

echo "Using JAVA_HOME=${JAVA_HOME}"
java -version
echo "Using Maven=$("${MAVEN_BIN}" -version | head -1)"
echo "Using settings=${SETTINGS_FILE}"
echo "Using deploy files=${DEPLOY_DIR} -> ${CONTAINER_DEPLOY_DIR}"
echo "Using socket.timeout=${SOCKET_TIMEOUT_MILLIS}"
echo "Using cmb.config.timeout.millis=${CMB_TIMEOUT_MILLIS}"
echo "Using unionpay.login.on.startup=${UNIONPAY_LOGIN_ON_STARTUP}"

"${MAVEN_BIN}" clean install \
  -s "${SETTINGS_FILE}" \
  -Dmaven.test.skip=true \
  -Dsocket.timeout="${SOCKET_TIMEOUT_MILLIS}" \
  -Dcmb.config.timeout.millis="${CMB_TIMEOUT_MILLIS}" \
  -Dunionpay.login.on.startup="${UNIONPAY_LOGIN_ON_STARTUP}" \
  -PdevProfile

docker build \
  --platform linux/amd64 \
  -f "${DOCKER_DIR}/Dockerfile" \
  -t "${IMAGE_NAME}" \
  "${PROJECT_DIR}"

docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HTTP_PORT}:8080" \
  -p "${JPDA_PORT}:5005" \
  -v "${DEPLOY_DIR}:${CONTAINER_DEPLOY_DIR}:ro" \
  "${IMAGE_NAME}"
