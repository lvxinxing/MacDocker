# bpg-new-vkereg local Docker

这个目录用于编译 `bpg-new` Maven 模块，并把 `target/*.war` 打进 Tomcat 的 `webapps/ROOT.war`。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/bpg-new-vkereg
./build-run.sh
```

脚本会先把同级的 `wsroot`（`oasis:bpg-webServiceRoot`）安装到本地 Maven 仓库，再编译 `bpg-new`。这样本地仓库里的依赖与 IDEA 多模块源码保持一致，避免出现枚举常量等“IDEA 能编、Maven 找不到符号”的问题。

默认值：

```bash
BPG_PROJECT_DIR=/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new
BPG_WSROOT_DIR=$BPG_PROJECT_DIR/../wsroot
SKIP_WSROOT_INSTALL=false
BPG_JAVA_HOME=自动查找本机 JDK 8
BPG_MAVEN_HOME=默认使用 /Users/paul/Documents/java/dockers/base/mvn/apache-maven-3.2.5-bin.tar.gz
SETTINGS_FILE=/Users/paul/.m2/settings.xml
BPG_DEPLOY_DIR=/Users/paul/Documents/java/Data/deploy
BPG_CONTAINER_DEPLOY_DIR=/Users/paul/Documents/java/Data/deploy
STOP_TIMEOUT_SECONDS=30
IMAGE_NAME=bpg-new-vkereg-app
CONTAINER_NAME=bpg-new-vkereg
HTTP_PORT=8086
JPDA_PORT=5011
```

若本地仓库里的 `bpg-webServiceRoot` 已经是最新，可跳过 wsroot 安装：

```bash
SKIP_WSROOT_INSTALL=true ./build-run.sh
```

脚本不会额外指定 `-Dmaven.repo.local`，本地仓库路径由 `/Users/paul/.m2/settings.xml` 里的配置决定。

重建容器时会先 `docker stop -t $STOP_TIMEOUT_SECONDS`，再 `docker rm`，给 Tomcat / Spring 一点优雅停机时间；避免直接 `docker rm -f` 立刻 SIGKILL。

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

应用部署为 Tomcat 根应用。启动完成后可用下面命令验证服务是否正常：

```bash
curl -v "http://localhost:8086/payment/tcb/test"
```

如果要临时使用别的端口或容器名：

```bash
HTTP_PORT=18082 JPDA_PORT=15007 CONTAINER_NAME=bpg-new-vkereg-test ./build-run.sh
```

## 停止容器时的 Aliyun SLS 报错

`log4j.properties` 把 rootLogger 配成了 `stdout, loghub`。停机时常见噪音：

```text
Closing the log producer...
log4j:ERROR Failed to send log...
IllegalStateException: cannot append after the log accumulator was closed
```

这是 `LoghubAppender` / `LogProducer` 关闭后，Spring/JMS/Tomcat 停机日志仍继续写入导致的竞态，**不影响启动和业务**。本地 Docker 若不想看这些栈，可把 rootLogger 改成只打控制台：

```properties
log4j.rootLogger=info, stdout
```

如果要手工分步执行：

```bash
JAVA_HOME=/Users/paul/Library/Java/JavaVirtualMachines/corretto-1.8.0_472/Contents/Home
MVN=/private/tmp/bpg-local-maven/apache-maven-3.2.5/bin/mvn

cd /Users/paul/Documents/java/IdeaProjects/bpg/wsroot
"$MVN" clean install -s /Users/paul/.m2/settings.xml -Dmaven.test.skip=true

cd /Users/paul/Documents/java/IdeaProjects/bpg/bpg-new
"$MVN" clean install \
  -s /Users/paul/.m2/settings.xml \
  -Dmaven.test.skip=true \
  -PdevProfile

docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/bpg-new-vkereg/Dockerfile \
  -t bpg-new-vkereg-app \
  /Users/paul/Documents/java/IdeaProjects/bpg/bpg-new

docker stop -t 30 bpg-new-vkereg || true
docker rm bpg-new-vkereg || true
docker run -d \
  --name bpg-new-vkereg \
  -p 8086:8080 \
  -p 5011:5005 \
  -v /Users/paul/Documents/java/Data/deploy:/Users/paul/Documents/java/Data/deploy:ro \
  bpg-new-vkereg-app
```

`Dockerfile.dockerignore` 只把 `target/*.war` 放进 Docker build context，避免把整个 bpg-new 源码和本地 Maven 仓库传给 Docker。
