# bpg-new-vkereg Docker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Simplify `app/bpg-new-vkereg` Docker deployment to build from the `bpg-new` Maven module with `devProfile` and the VKE Tomcat 7 image.

**Architecture:** `build-run.sh` runs Maven inside `/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new`, then builds a Docker image using that module directory as the context. `Dockerfile` copies `target/*.war` into Tomcat as `bpg-service.war`; `.dockerignore` allows only the WAR output into the build context.

**Tech Stack:** Bash, Maven 3.2.5, JDK 8, Docker, Tomcat 7 base image `vkereg.800best.com/bestbase/besttomcat7:jre7-python3`.

## Global Constraints

- Default Maven project directory is `/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new`.
- Maven profile is `devProfile`.
- Docker base image is `vkereg.800best.com/bestbase/besttomcat7:jre7-python3`.
- Tomcat deployment name is `bpg-service.war`.
- Preserve existing defaults for image name, container name, HTTP port, JPDA port, Maven settings, and Maven cache.

---

### Task 1: Simplify deployment files

**Files:**
- Modify: `app/bpg-new-vkereg/build-run.sh`
- Modify: `app/bpg-new-vkereg/Dockerfile`
- Modify: `app/bpg-new-vkereg/Dockerfile.dockerignore`
- Modify: `app/bpg-new-vkereg/README.md`

**Interfaces:**
- Consumes: `BPG_PROJECT_DIR`, `BPG_JAVA_HOME`, `BPG_MAVEN_HOME`, `SETTINGS_FILE`, `IMAGE_NAME`, `CONTAINER_NAME`, `HTTP_PORT`, `JPDA_PORT`.
- Produces: `./build-run.sh` that compiles, builds, removes the old container, and runs the new container.

- [x] **Step 1: Replace `build-run.sh` with the simplified flow**

Use `BPG_PROJECT_DIR=/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new`, keep Java and Maven detection, run Maven with `-PdevProfile`, remove temp-context and local `jdk7-base` logic, and run `docker build --platform linux/amd64 -f "${DOCKER_DIR}/Dockerfile" -t "${IMAGE_NAME}" "${PROJECT_DIR}"`.

- [x] **Step 2: Update `Dockerfile`**

Use `FROM --platform=linux/amd64 vkereg.800best.com/bestbase/besttomcat7:jre7-python3`, set Shanghai timezone, keep Java/Tomcat debug options, copy `target/*.war` to `/usr/local/tomcat/webapps/bpg-service.war`, expose `8080 5005`, and run `catalina.sh jpda run`.

- [x] **Step 3: Update `Dockerfile.dockerignore`**

Allow only `target/*.war` from the `bpg-new` module context.

- [x] **Step 4: Update `README.md`**

Document the module path, `devProfile`, VKE base image, and simplified manual build commands.

- [x] **Step 5: Verify syntax and consistency**

Run: `bash -n app/bpg-new-vkereg/build-run.sh`

Expected: no output and exit code `0`.

Run: `git diff -- app/bpg-new-vkereg`

Expected: only the four deployment files changed, with no references to `uatProfile`, `jdk7-base`, temporary Docker build contexts, or `/Users/paul/Documents/java/IdeaProjects/bpg` as the default project directory.
