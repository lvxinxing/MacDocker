# app Docker deployments

本目录下 6 个本地部署单元的默认端口规划如下，HTTP 和 JPDA 端口都不冲突：

| 部署单元 | 容器名 | 镜像名 | HTTP 端口 | JPDA 端口 | 说明 |
| --- | --- | --- | --- | --- | --- |
| bdc | bdc | bdc-app | 8083 | 5008 | 原本地挂载 WAR 流程 |
| bdc-vkereg | bdc-vkereg | bdc-vkereg-app | 8084 | 5009 | Maven 编译后打包 WAR 到镜像 |
| f1 | f1 | f1-app | 8081 | 5006 | 原本地挂载 WAR 流程 |
| f1-vkereg | f1-vkereg | f1-vkereg-app | 8085 | 5010 | Maven 编译后打包 WAR 到镜像 |
| bpg-new | bpg-new | bpg-new-app | 8082 | 5007 | 原本地挂载项目目录并容器内编译 |
| bpg-new-vkereg | bpg-new-vkereg | bpg-new-vkereg-app | 8086 | 5011 | Maven 编译后解压 WAR 到 Tomcat |

`*-vkereg` 目录里的 `build-run.sh` 支持通过环境变量覆盖容器名和端口，例如：

```bash
HTTP_PORT=18086 JPDA_PORT=15011 CONTAINER_NAME=bpg-new-vkereg-test ./build-run.sh
```
