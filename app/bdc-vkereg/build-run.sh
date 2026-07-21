#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${BDC_PROJECT_DIR:-/Users/paul/Documents/java/IdeaProjects/bdc}"
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERS_DIR="$(cd "${DOCKER_DIR}/../.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-bdc-vkereg-app}"
CONTAINER_NAME="${CONTAINER_NAME:-bdc-vkereg}"
HTTP_PORT="${HTTP_PORT:-8084}"
JPDA_PORT="${JPDA_PORT:-5009}"
SETTINGS_FILE="${SETTINGS_FILE:-/Users/paul/.m2/settings.xml}"
MAVEN_VERSION="${MAVEN_VERSION:-3.2.5}"
MAVEN_CACHE_DIR="${MAVEN_CACHE_DIR:-/private/tmp/bdc-local-maven}"

detect_java_home() {
  if [[ -n "${BDC_JAVA_HOME:-}" ]]; then
    echo "${BDC_JAVA_HOME}"
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
  if [[ -n "${BDC_MAVEN_HOME:-}" ]]; then
    echo "${BDC_MAVEN_HOME}/bin/mvn"
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

cleanup_war_conflicts() {
  local war_file="${PROJECT_DIR}/server/flex/war/target/bdc-flex-war.war"

  if [[ ! -f "${war_file}" ]]; then
    echo "WAR file was not found: ${war_file}" >&2
    exit 1
  fi

  local stale_spring_jars=(
    "WEB-INF/lib/org.springframework.aop-3.2.1.RELEASE.jar"
    "WEB-INF/lib/org.springframework.beans-3.2.1.RELEASE.jar"
    "WEB-INF/lib/org.springframework.context-3.2.1.RELEASE.jar"
    "WEB-INF/lib/org.springframework.core-3.2.1.RELEASE.jar"
    "WEB-INF/lib/org.springframework.transaction-3.2.1.RELEASE.jar"
  )

  echo "Removing duplicate old Spring jars from ${war_file}"
  for stale_jar in "${stale_spring_jars[@]}"; do
    if jar tf "${war_file}" | grep -Fqx "${stale_jar}"; then
      zip -q -d "${war_file}" "${stale_jar}"
      echo "  removed ${stale_jar}"
    fi
  done
}

JAVA_HOME_FOR_BUILD="$(detect_java_home)"
if [[ -z "${JAVA_HOME_FOR_BUILD}" ]]; then
  echo "JDK 8 was not found. Set BDC_JAVA_HOME to a JDK 8 home before running this script." >&2
  exit 1
fi

MAVEN_BIN="$(detect_maven_bin)"
if [[ -z "${MAVEN_BIN}" || ! -x "${MAVEN_BIN}" ]]; then
  echo "Maven ${MAVEN_VERSION} was not found. Set BDC_MAVEN_HOME before running this script." >&2
  exit 1
fi

if [[ ! -f "${SETTINGS_FILE}" ]]; then
  echo "Maven settings file was not found: ${SETTINGS_FILE}" >&2
  exit 1
fi

export JAVA_HOME="${JAVA_HOME_FOR_BUILD}"
export PATH="${JAVA_HOME}/bin:${PATH}"

cd "${PROJECT_DIR}"

echo "Using JAVA_HOME=${JAVA_HOME}"
java -version
echo "Using Maven=$("${MAVEN_BIN}" -version | head -1)"
echo "Using settings=${SETTINGS_FILE}"

"${MAVEN_BIN}" clean install \
  -s "${SETTINGS_FILE}" \
  -Dmaven.test.skip=true \
  -PtestRelease

cleanup_war_conflicts

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
  "${IMAGE_NAME}"
