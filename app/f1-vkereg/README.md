# f1-vkereg local Docker

这个目录用于参照测试服务器方式编译 f1，并把 `server/flex/war/target/f1-flex-war.war` 打进 Docker 镜像。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/f1-vkereg
./build-run.sh
```

默认值：

```bash
F1_PROJECT_DIR=/Users/paul/Documents/java/IdeaProjects/f1
F1_JAVA_HOME=自动查找本机 JDK 8
F1_MAVEN_HOME=默认使用 /Users/paul/Documents/java/dockers/base/mvn/apache-maven-3.2.5-bin.tar.gz
SETTINGS_FILE=/Users/paul/.m2/settings.xml
IMAGE_NAME=f1-vkereg-app
CONTAINER_NAME=f1-vkereg
HTTP_PORT=8085
JPDA_PORT=5010
```

脚本不会额外指定 `-Dmaven.repo.local`，本地仓库路径由 `/Users/paul/.m2/settings.xml` 里的配置决定。

f1 的 `server/flex/war/pom.xml` 使用了旧版 `maven-antrun-plugin` 的 `<tasks>` 写法，所以脚本默认使用 Maven 3.2.5。不要直接用 Homebrew Maven 3.9.x 编译，否则可能解析到 `maven-antrun-plugin:3.1.0` 并报 `tasks has been removed`。

WAR 包里可能因为 `org.springframework:org.springframework.transaction:3.2.1.RELEASE` 传递依赖混入旧命名 Spring jar，例如 `org.springframework.core-3.2.1.RELEASE.jar`。它会和项目主版本 `spring-core-3.2.18.RELEASE.jar` 冲突，导致 Tomcat 启动时报 `ClassUtils.determineCommonAncestor` 的 `NoSuchMethodError`。脚本会在 Maven 编译后自动从 WAR 中删除这些旧命名 Spring 3.2.1 jar。

f1 还会打入 `spring-asm-3.1.4.RELEASE.jar`，它和 `spring-core-3.2.18.RELEASE.jar` 内置的 `org.springframework.asm` 类冲突，可能导致 `ClassMetadataReadingVisitor has interface org.springframework.asm.ClassVisitor as super class`。脚本也会自动删除这个旧 `spring-asm` jar。

如果要和原本手工流程一样只构建镜像、但不先编译，可以先用 IDEA 产出 WAR 后手工执行：

```bash
docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/f1-vkereg/Dockerfile \
  -t f1-vkereg-app \
  /Users/paul/Documents/java/IdeaProjects/f1

docker rm -f f1-vkereg || true
docker run -d \
  --name f1-vkereg \
  -p 8085:8080 \
  -p 5010:5005 \
  f1-vkereg-app
```

`Dockerfile.dockerignore` 只把 `server/flex/war/target/f1-flex-war.war` 放进 Docker build context，避免把整个 f1 源码和本地 Maven 仓库传给 Docker。
