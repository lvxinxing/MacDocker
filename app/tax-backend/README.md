# tax-backend local Docker

这个目录用于在本机用 JDK 17 编译 `tax-backend`，并把 `tax-server/target/tax-server.jar` 打进 Docker 镜像。容器固定使用 Spring `dev` 和公司 Apollo `DEV`；数据库 URL、账号、密码等由 Apollo DEV 的同名键提供。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/tax-backend
./build-run.sh
```

默认值：

```bash
TAX_BACKEND_DIR=/Users/paul/Documents/workspace/best-tax/tax-backend
TAX_JAVA_HOME=/Users/paul/Library/Java/JavaVirtualMachines/corretto-17.0.17/Contents/Home
TAX_MAVEN_HOME=默认使用 Homebrew Maven 3.9.x（`mvn`）
SETTINGS_FILE=/Users/paul/.m2/settings.xml
SPRING_PROFILES_ACTIVE=dev
APOLLO_ENV=DEV（脚本固定，不接受覆盖）
APOLLO_META=必填；本地 tax-local 无法解析 apollo.meta，必须传 DEV Meta 地址
IMAGE_NAME=tax-backend-app
CONTAINER_NAME=tax-backend
NETWORK_NAME=tax-local
HTTP_PORT=48081
JPDA_PORT=5012
FRONTEND_HTTP_PORT=3200
ADMIN_UI_URL=http://localhost:3200
```

宿主机端口故意避开本机 IDE 调试占用的 `48080`。容器内仍监听 `48080`，与 Spring `server.port` 一致。

`dev` 会把 CAS / Admin UI 回跳指到 Docker 前端（默认 `http://localhost:3200`），避免跳回本机 Vite `5173`。

脚本不会额外指定 `-Dmaven.repo.local`，本地仓库路径由 `/Users/paul/.m2/settings.xml` 决定。

启动完成后可用下面命令验证服务是否正常：

```bash
curl -s "http://localhost:48081/actuator/health"
./verify-lan.sh   # 容器内 ping / nc / telnet 10.64.228.217:3306 与 :6379
```

本地 Docker **必须**使用 Spring `dev` 并读取 Apollo `DEV`。不要改成 `test`；实际数据库与 Redis 地址以 DEV 当前发布值为准。
`tax-local` 网桥必须能访问 DEV 发布的局域网地址；若 Java 仍报 `Access denied`，那是 MySQL 账号 host 授权，不是端口不通。
本机出口 IP 是 `en8` 的 `10.64.231.234`（与 `10.64.228.217` 同 /22）。

Apollo 配置发布后，通过宿主机环境变量传入 DEV Meta 地址。该参数为本地 Docker 必填项；脚本只打印“provided”，不会打印地址或配置值：

```bash
APOLLO_META='由运维提供的测试平台 Meta 地址' ./build-run.sh
```

脚本固定把 `ENV=DEV` 传入容器，避免本地联调误读 TEST 或 PRO。若公司平台调整环境名，应评审并修改脚本，不允许在单次启动中临时覆盖。

如果要临时使用别的端口或容器名：

```bash
HTTP_PORT=18081 JPDA_PORT=15012 CONTAINER_NAME=tax-backend-test ./build-run.sh
```

也可以手工分步执行：

```bash
cd /Users/paul/Documents/workspace/best-tax/tax-backend
JAVA_HOME=/Users/paul/Library/Java/JavaVirtualMachines/corretto-17.0.17/Contents/Home \
  mvn -pl tax-server -am clean package -s /Users/paul/.m2/settings.xml -Dmaven.test.skip=true

docker network create tax-local >/dev/null 2>&1 || true

docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/tax-backend/Dockerfile \
  -t tax-backend-app \
  /Users/paul/Documents/workspace/best-tax/tax-backend

docker stop -t 30 tax-backend || true
docker rm tax-backend || true
docker run -d \
  --name tax-backend \
  --network tax-local \
  --add-host=host.docker.internal:host-gateway \
  -p 48081:48080 \
  -p 5012:5005 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e ENV=DEV \
  -e APOLLO_META='由运维提供的测试平台 Meta 地址' \
  -e 'ARGS=--tax.web.admin-ui.url=http://localhost:3200 --tax.cas.server-url=http://localhost:3200 --tax.cas.success-redirect-url=http://localhost:3200 --tax.cas.failure-redirect-url=http://localhost:3200/403' \
  tax-backend-app
```

`Dockerfile.dockerignore` 只把 `tax-server/target/tax-server.jar` 放进 Docker build context，避免把整个源码和本地 Maven 仓库传给 Docker。

基础镜像默认是公司仓库的 `vkereg.800best.com/bestbase/bestjava:17`（OpenJDK 17）。本地 Docker Hub 经常超时，不要默认走 `eclipse-temurin`。仓库里的 VKE `tax-server/Dockerfile` 也已升级为 Java 17，并通过 profile 守卫只允许 test/prod。

如需覆盖基础镜像：

```bash
docker build --build-arg BASE_IMAGE=eclipse-temurin:17-jre-jammy ...
```
