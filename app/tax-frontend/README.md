# tax-frontend local Docker

这个目录用于在本机编译 `tax-frontend`（Vite `build:prod`），再把 `express-server/`（含 `public/` 静态产物）打进 Node 镜像。容器内 Express 托管页面，并把 `/admin-api` 反代到 Docker 网络里的 `tax-backend`。

一键编译、构建镜像并启动容器：

```bash
cd /Users/paul/Documents/java/dockers/app/tax-frontend
./build-run.sh
```

请先启动 [../tax-backend](../tax-backend)，或一次拉起前后端：

```bash
cd /Users/paul/Documents/java/dockers/app
./tax-backend/build-run.sh && ./tax-frontend/build-run.sh
```

默认值：

```bash
TAX_FRONTEND_DIR=/Users/paul/Documents/workspace/best-tax/tax-frontend
IMAGE_NAME=tax-frontend-app
CONTAINER_NAME=tax-frontend
NETWORK_NAME=tax-local
HTTP_PORT=3200
CONTAINER_PORT=3200
API_TARGET=http://tax-backend:48080/admin-api
NPM_REGISTRY=https://registry.npmmirror.com
```

宿主机端口故意避开本机 Vite 调试占用的 `5173`。浏览器访问 `http://localhost:3200`，API 走同源 `/admin-api`。

Express 把代理挂在 `/admin-api` 上会剥掉这段前缀，转发给后端时变成 `/system/...`。本地 Docker **不改业务代码**，只把 `API_TARGET` 写成带 `/admin-api` 的地址，由 http-proxy 的 `prependPath` 把前缀补回去。覆盖该变量时也要带上 `/admin-api`，例如 `http://host.docker.internal:48080/admin-api`。

VKE 参考脚本使用 `nuget.800best.com/netbase/library/node:16-buster-slim` 和 `API_TARGET=http://localhost:48080`。本目录沿用该 Node 16 基础镜像（Vite 构建在宿主机用 Node 20+ 完成）；`localhost:48080` 在容器内会指向自己，所以默认改成 Docker 网络里的 `tax-backend`。镜像内 `npm install` 带 `--ignore-engines`，因为 `express-server` 的 engines 声明了 `>=20.11.0`。

启动完成后可用下面命令验证服务是否正常：

```bash
curl -s "http://localhost:3200/healthz"
```

如果要临时使用别的端口，或把 API 指回本机 IDE 后端：

```bash
HTTP_PORT=13200 API_TARGET=http://host.docker.internal:48080/admin-api ./build-run.sh
```

也可以手工分步执行：

```bash
cd /Users/paul/Documents/workspace/best-tax/tax-frontend
npm config set registry https://registry.npmmirror.com
npm install
npm run build:prod

docker network create tax-local >/dev/null 2>&1 || true

docker build --platform linux/amd64 \
  -f /Users/paul/Documents/java/dockers/app/tax-frontend/Dockerfile \
  -t tax-frontend-app \
  /Users/paul/Documents/workspace/best-tax/tax-frontend

docker stop -t 10 tax-frontend || true
docker rm tax-frontend || true
docker run -d \
  --name tax-frontend \
  --network tax-local \
  --add-host=host.docker.internal:host-gateway \
  -p 3200:3200 \
  -e PORT=3200 \
  -e API_TARGET=http://tax-backend:48080/admin-api \
  tax-frontend-app
```

`Dockerfile.dockerignore` 只把 `express-server/`（不含本机 `node_modules`）放进 Docker build context，依赖在镜像内按 Linux 重新安装。
