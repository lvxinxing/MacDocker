# bpg-new-vkereg Docker 部署配置设计

## 目标

参照 `app/f1-vkereg` 简化 `app/bpg-new-vkereg` 的本地编译、镜像构建和容器启动流程，并使用指定的 VKE Tomcat 7 基础镜像。

## 目录约定

- Maven 项目目录：`/Users/paul/Documents/java/IdeaProjects/bpg/bpg-new`
- Docker 配置目录：`app/bpg-new-vkereg`
- Maven 输出目录：`${BPG_PROJECT_DIR}/target`
- Tomcat 部署名：`bpg-service.war`

`BPG_PROJECT_DIR` 直接指向 `bpg-new` Maven 模块，同时作为 Maven 工作目录和 Docker 构建上下文。

## 构建与部署流程

1. 使用 JDK 8 和 Maven 3.2.5 在 `${BPG_PROJECT_DIR}` 执行：
   `mvn clean install -s ${SETTINGS_FILE} -Dmaven.test.skip=true -PdevProfile`
2. 使用 `app/bpg-new-vkereg/Dockerfile` 和 `${BPG_PROJECT_DIR}` 构建 `linux/amd64` 镜像。
3. Dockerfile 基于
   `vkereg.800best.com/bestbase/besttomcat7:jre7-python3`。
4. 将 `target/*.war` 复制为
   `/usr/local/tomcat/webapps/bpg-service.war`，由 Tomcat 自动部署。
5. 删除同名旧容器，再以既有 HTTP 和 JPDA 端口映射启动新容器。

## 精简范围

从 `build-run.sh` 删除以下 BPG 专属复杂逻辑：

- 临时 Docker 构建上下文创建和清理
- WAR 文件复制到临时目录
- 本地 `jdk7-base` 镜像检查与自动构建
- `DOCKER_BUILDKIT=0` 和相关兼容处理

保留与 `f1-vkereg` 一致的 JDK 8 检测、Maven 3.2.5 获取、Maven settings 校验、镜像构建和容器重建流程。

## 配套文件

- `Dockerfile`：切换基础镜像并直接复制 WAR。
- `Dockerfile.dockerignore`：仅允许 `target/*.war` 进入构建上下文。
- `README.md`：更新项目路径、`devProfile`、基础镜像及手工执行示例。

## 验证

- 对 `build-run.sh` 执行 `bash -n`。
- 检查 Dockerfile、dockerignore 和 README 中的路径、镜像及 Maven profile 一致。
- 若本机依赖和私有镜像仓库可用，执行完整构建启动并检查容器状态。
