# bpg-new local Docker

流程：在本目录构建镜像；容器启动后挂载 bpg 源码，在容器内 `mvn package`，再把 WAR 部署到 Tomcat。

Maven 使用宿主机 `/Users/paul/.m2/settings.xml`，对应本地仓库为 `/Users/paul/.m2/repository`，因此两者都需挂进容器（仓库按绝对路径挂载，与 settings 中的 `localRepository` 一致）。

```bash
cd /Users/paul/Documents/java/dockers/app/bpg-new

docker build -t bpg-new-app .

docker run -d \
  --name bpg-new \
  -p 8082:8080 \
  -p 5007:5005 \
  -v /Users/paul/Documents/java/IdeaProjects/bpg:/workspace \
  -v /Users/paul/.m2/settings.xml:/root/.m2/settings.xml \
  -v /Users/paul/.m2/repository:/Users/paul/.m2/repository \
  bpg-new-app
```

默认端口：

| 项 | 值 |
| --- | --- |
| 容器名 | bpg-new |
| 镜像名 | bpg-new-app |
| HTTP | 8082 |
| JPDA | 5007 |
| Context | `/bpg-new` |

容器启动后会先编译再部署；首次启动可能较久。完成后验证：

```bash
curl -v "http://localhost:8082/bpg-new/payment/tcb/test"
```
