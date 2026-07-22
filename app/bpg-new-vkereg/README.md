# bpg-new-vkereg local Docker

这个目录用于编译 `bpg-new` Maven 模块，并把 `target/*.war` 打进 Tomcat 的 `webapps/ROOT.war`。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/bpg-new-vkereg
./build-run.sh
```

默认值：

```bash
BPG_PROJECT_DIR=/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new
BPG_JAVA_HOME=自动查找本机 JDK 8
BPG_MAVEN_HOME=默认使用 /Users/paul/Documents/java/dockers/base/mvn/apache-maven-3.2.5-bin.tar.gz
SETTINGS_FILE=/Users/paul/.m2/settings.xml
BPG_DEPLOY_DIR=/Users/paul/Documents/java/Data/deploy
BPG_CONTAINER_DEPLOY_DIR=/Users/paul/Documents/java/Data/deploy
SOCKET_TIMEOUT_MILLIS=3000
CMB_TIMEOUT_MILLIS=3000
UNIONPAY_LOGIN_ON_STARTUP=false
IMAGE_NAME=bpg-new-vkereg-app
CONTAINER_NAME=bpg-new-vkereg
HTTP_PORT=8086
JPDA_PORT=5011
```

脚本不会额外指定 `-Dmaven.repo.local`，本地仓库路径由 `/Users/paul/.m2/settings.xml` 里的配置决定。

本地 Docker 默认关闭银联启动期登录，并把 socket/CMB 超时降到 3000ms，避免前置机不可达时拖慢 Tomcat 启动。需要恢复原行为时可覆盖：

```bash
UNIONPAY_LOGIN_ON_STARTUP=true SOCKET_TIMEOUT_MILLIS=60000 CMB_TIMEOUT_MILLIS=360000 ./build-run.sh
```

`Dockerfile` 基于 VKE 使用的 Tomcat 7 镜像 `vkereg.800best.com/bestbase/besttomcat7:jre7-python3`。

脚本直接以 `BPG_PROJECT_DIR` 作为 Docker build context。`Dockerfile.dockerignore` 只放行 `target/*.war`，避免把源码和本地 Maven 仓库传给 Docker。

容器运行时会把 `BPG_DEPLOY_DIR` 只读挂载到 `BPG_CONTAINER_DEPLOY_DIR`，默认两边都是 `/Users/paul/Documents/java/Data/deploy`，确保容器内运行时文件路径与 `pom.xml` 的 `devProfile` 配置一致。`bpg-new` 的 Spring context 启动时会读取 OCB 证书，如果缺少下面文件，应用会启动失败并导致接口 404：

```bash
$BPG_DEPLOY_DIR/cert/ocb/ocb.key
$BPG_DEPLOY_DIR/cert/ocb/ocb.pem
$BPG_DEPLOY_DIR/cert/ocb/public-cert.pem
```

Maven 编译命令对应测试服务器：

```bash
mvn clean install -Dmaven.test.skip=true -PdevProfile
```

Docker 部署方式：

```bash
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war
```

应用部署为 Tomcat 根应用，启动后访问：

```bash
http://localhost:8086/payment/tcb/test
```

如果要临时使用别的端口或容器名：

```bash
HTTP_PORT=18082 JPDA_PORT=15007 CONTAINER_NAME=bpg-new-vkereg-test ./build-run.sh
```

如果要手工分步执行：

```bash
cd /Users/paul/Documents/java/IdeaProjects/bpg/bpg-new
JAVA_HOME=/Users/paul/Library/Java/JavaVirtualMachines/corretto-1.8.0_472/Contents/Home \
  /private/tmp/bpg-local-maven/apache-maven-3.2.5/bin/mvn clean install \
  -s /Users/paul/.m2/settings.xml \
  -Dmaven.test.skip=true \
  -Dsocket.timeout=3000 \
  -Dcmb.config.timeout.millis=3000 \
  -Dunionpay.login.on.startup=false \
  -PdevProfile

docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/bpg-new-vkereg/Dockerfile \
  -t bpg-new-vkereg-app \
  /Users/paul/Documents/java/IdeaProjects/bpg/bpg-new

docker rm -f bpg-new-vkereg || true
docker run -d \
  --name bpg-new-vkereg \
  -p 8086:8080 \
  -p 5011:5005 \
  -v /Users/paul/Documents/java/Data/deploy:/Users/paul/Documents/java/Data/deploy:ro \
  bpg-new-vkereg-app
```

`Dockerfile.dockerignore` 只把 `target/*.war` 放进 Docker build context，避免把整个 bpg-new 源码和本地 Maven 仓库传给 Docker。
