# app Docker deployments

本目录下本地部署单元的默认端口规划如下，HTTP 和 JPDA 端口都不冲突：

| 部署单元 | 容器名 | 镜像名 | HTTP 端口 | JPDA 端口 | 说明 |
| --- | --- | --- | --- | --- | --- |
| f1 | f1 | f1-app | 8081 | 5006 | IDEA Build Artifacts 后挂载 WAR |
| bpg-new | bpg-new | bpg-new-app | 8082 | 5007 | 挂载源码，容器内 Maven 编译 |
| bdc | bdc | bdc-app | 8083 | 5008 | IDEA Build Artifacts 后挂载 WAR |
| bdc-vkereg | bdc-vkereg | bdc-vkereg-app | 8084 | 5009 | Maven 编译后打包 WAR 到镜像 |
| f1-vkereg | f1-vkereg | f1-vkereg-app | 8085 | 5010 | Maven 编译后打包 WAR 到镜像 |
| bpg-new-vkereg | bpg-new-vkereg | bpg-new-vkereg-app | 8086 | 5011 | Maven 编译后解压 WAR 到 Tomcat |
| tax-backend | tax-backend | tax-backend-app | 48081 | 5012 | Maven 编译 JAR，Spring `dev` |
| tax-frontend | tax-frontend | tax-frontend-app | 3200 | — | Vite `build:prod` + Express 反代 |

`*-vkereg` 目录里的 `build-run.sh` 支持通过环境变量覆盖容器名和端口，例如：

```bash
HTTP_PORT=18086 JPDA_PORT=15011 CONTAINER_NAME=bpg-new-vkereg-test ./build-run.sh
```

## 启动后验证

各服务启动完成后，可用下面命令验证是否正常（端口与上表默认 HTTP 端口一致）：

```bash
# f1 (8081) — context: /f1-flex-war
curl -v "http://localhost:8081/f1-flex-war/web/api/supplierPaymentRequest/getPaymentRequest?id=100"

# bpg-new (8082) — context: /bpg-new
curl -v "http://localhost:8082/bpg-new/payment/tcb/test"

# bdc (8083) — context: /bdc-flex-war
curl -v "http://localhost:8083/bdc-flex-war/web/api/accountingInterval/get/68255"

# bdc-vkereg (8084) — context: /bdc-flex-war
curl -v "http://localhost:8084/bdc-flex-war/web/api/accountingInterval/get/68255"

# f1-vkereg (8085) — context: /f1-flex-war
curl -v "http://localhost:8085/f1-flex-war/web/api/supplierPaymentRequest/getPaymentRequest?id=100"

# bpg-new-vkereg (8086) — context: / (ROOT.war)
curl -v "http://localhost:8086/payment/tcb/test"

# tax-backend (48081) — 避开本机 IDE 的 48080
curl -s "http://localhost:48081/actuator/health"

# tax-frontend (3200) — 避开本机 Vite 的 5173
curl -s "http://localhost:3200/healthz"
```

说明：

- `f1` / `f1-vkereg`、`bdc` / `bdc-vkereg` 部署的 WAR 名分别为 `f1-flex-war.war`、`bdc-flex-war.war`，因此 URL 带对应 context path。
- `bpg-new` 部署为 `bpg-new.war`（context `/bpg-new`）；`bpg-new-vkereg` 部署为 `ROOT.war`（无 context 前缀）。
- 若启动时覆盖了 `HTTP_PORT`，请把上面 URL 中的端口一并改成实际端口。

各目录详细部署命令见：

- [f1/README.md](f1/README.md)
- [bpg-new/README.md](bpg-new/README.md)
- [bdc/README.md](bdc/README.md)
- [f1-vkereg/README.md](f1-vkereg/README.md)
- [bdc-vkereg/README.md](bdc-vkereg/README.md)
- [bpg-new-vkereg/README.md](bpg-new-vkereg/README.md)
- [tax-backend/README.md](tax-backend/README.md)
- [tax-frontend/README.md](tax-frontend/README.md)

税务前后端一键部署（先后端再前端，共用 Docker 网络 `tax-local`）：

```bash
cd /Users/paul/Documents/java/dockers/app
./tax-backend/build-run.sh && ./tax-frontend/build-run.sh
```
