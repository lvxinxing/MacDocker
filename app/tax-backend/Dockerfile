ARG BASE_IMAGE=vkereg.800best.com/bestbase/bestjava:17
FROM ${BASE_IMAGE}

LABEL app="tax-backend"

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# ping / telnet / nc：用于从容器验证局域网 tax_dev 的 3306/6379。源偶发 502，故重试。
RUN set -eux; \
    i=1; \
    until apt-get update \
      && apt-get install -y --no-install-recommends --fix-missing \
           iputils-ping telnet netcat-openbsd; do \
      if [ "$i" -ge 6 ]; then exit 1; fi; \
      echo "apt-get failed, retry $i"; \
      i=$((i+1)); \
      sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY tax-server/target/tax-server.jar /app.jar

ENV JAVA_OPTS="-Xms512m -Xmx2048m -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 -Djava.security.egd=file:/dev/./urandom -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
ENV SPRING_PROFILES_ACTIVE=dev
ENV ARGS=""

EXPOSE 48080 5005

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app.jar --spring.profiles.active=$SPRING_PROFILES_ACTIVE $ARGS"]
