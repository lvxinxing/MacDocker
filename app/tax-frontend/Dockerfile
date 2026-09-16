ARG BASE_IMAGE=nuget.800best.com/netbase/library/node:16-buster-slim
FROM --platform=linux/amd64 ${BASE_IMAGE}

LABEL app="tax-frontend"

WORKDIR /app
COPY ./express-server .

ENV NODE_ENV=production
ENV PORT=3200
ENV API_TARGET=http://tax-backend:48080/admin-api

RUN npm config set strict-ssl false \
    && npm install --omit=dev --ignore-engines --registry=https://registry.npmmirror.com \
    && chmod -R 711 node_modules/

EXPOSE 3200

ENTRYPOINT ["node", "server.js"]
