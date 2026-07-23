# f1 local Docker

先在 IntelliJ IDEA 中对 f1 执行 **Build Artifacts**，产出：

`/Users/paul/Documents/java/IdeaProjects/f1/server/flex/war/target/f1-flex-war.war`

再在本目录构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/f1

docker build -t f1-app .

docker run -d \
  --name f1 \
  -p 8081:8080 \
  -p 5006:5005 \
  -v /Users/paul/Documents/java/IdeaProjects/f1/server/flex/war/target/f1-flex-war.war:/usr/local/tomcat/webapps/f1-flex-war.war \
  f1-app
```

默认端口：

| 项 | 值 |
| --- | --- |
| 容器名 | f1 |
| 镜像名 | f1-app |
| HTTP | 8081 |
| JPDA | 5006 |
| Context | `/f1-flex-war` |

启动完成后验证：

```bash
curl -v "http://localhost:8081/f1-flex-war/web/api/supplierPaymentRequest/getPaymentRequest?id=100"
```
