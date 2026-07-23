# bdc-vkereg local Docker

这个目录用于参照测试服务器方式编译 bdc，并把 `server/flex/war/target/bdc-flex-war.war` 打进 Docker 镜像。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/bdc-vkereg
./build-run.sh
```

默认值：

```bash
BDC_PROJECT_DIR=/Users/paul/Documents/java/IdeaProjects/bdc
BDC_JAVA_HOME=自动查找本机 JDK 8
BDC_MAVEN_HOME=默认使用 /Users/paul/Documents/java/dockers/base/mvn/apache-maven-3.2.5-bin.tar.gz
SETTINGS_FILE=/Users/paul/.m2/settings.xml
IMAGE_NAME=bdc-vkereg-app
CONTAINER_NAME=bdc-vkereg
HTTP_PORT=8084
JPDA_PORT=5009
```

脚本不会额外指定 `-Dmaven.repo.local`，本地仓库路径由 `/Users/paul/.m2/settings.xml` 里的配置决定。

启动完成后可用下面命令验证服务是否正常：

```bash
curl -v "http://localhost:8084/bdc-flex-war/web/api/accountingInterval/get/68255"
```

如果要临时使用别的端口或容器名：

```bash
HTTP_PORT=18084 JPDA_PORT=15009 CONTAINER_NAME=bdc-vkereg-test ./build-run.sh
```

bdc 的 `server/flex/war/pom.xml` 使用了旧版 `maven-antrun-plugin` 的 `<tasks>` 写法，所以脚本默认使用 Maven 3.2.5。不要直接用 Homebrew Maven 3.9.x 编译，否则可能解析到 `maven-antrun-plugin:3.1.0` 并报 `tasks has been removed`。

WAR 包里还可能因为 `org.springframework:org.springframework.transaction:3.2.1.RELEASE` 传递依赖混入旧命名 Spring jar，例如 `org.springframework.core-3.2.1.RELEASE.jar`。它会和项目主版本 `spring-core-3.2.18.RELEASE.jar` 冲突，导致 Tomcat 启动时报 `ClassUtils.determineCommonAncestor` 的 `NoSuchMethodError`。脚本会在 Maven 编译后自动从 WAR 中删除这些旧命名 Spring 3.2.1 jar。

也可以手工分步执行：

```bash
cd /Users/paul/Documents/java/IdeaProjects/bdc
JAVA_HOME=/Users/paul/Library/Java/JavaVirtualMachines/corretto-1.8.0_472/Contents/Home \
  /private/tmp/bdc-local-maven/apache-maven-3.2.5/bin/mvn clean install -s /Users/paul/.m2/settings.xml -Dmaven.test.skip=true -PtestRelease

docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/bdc-vkereg/Dockerfile \
  -t bdc-vkereg-app \
  /Users/paul/Documents/java/IdeaProjects/bdc

docker rm -f bdc-vkereg || true
docker run -d \
  --name bdc-vkereg \
  -p 8084:8080 \
  -p 5009:5005 \
  bdc-vkereg-app
```

`Dockerfile.dockerignore` 只把 `server/flex/war/target/bdc-flex-war.war` 放进 Docker build context，避免把整个 bdc 源码和本地 Maven 仓库传给 Docker。
