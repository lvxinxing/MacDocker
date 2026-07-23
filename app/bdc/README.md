# bdc local Docker

先在 IntelliJ IDEA 中对 bdc 执行 **Build Artifacts**，产出：

`/Users/paul/Documents/java/IdeaProjects/bdc/server/flex/war/target/bdc-flex-war.war`

再在本目录构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/bdc

docker build -t bdc-app .

docker run -d \
  --name bdc \
  -p 8083:8080 \
  -p 5008:5005 \
  -v /Users/paul/Documents/java/IdeaProjects/bdc/server/flex/war/target/bdc-flex-war.war:/usr/local/tomcat/webapps/bdc-flex-war.war \
  bdc-app
```

默认端口：

| 项 | 值 |
| --- | --- |
| 容器名 | bdc |
| 镜像名 | bdc-app |
| HTTP | 8083 |
| JPDA | 5008 |
| Context | `/bdc-flex-war` |

启动完成后验证：

```bash
curl -v "http://localhost:8083/bdc-flex-war/web/api/accountingInterval/get/68255"
```
