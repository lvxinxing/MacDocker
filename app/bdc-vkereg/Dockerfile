FROM --platform=linux/amd64 reg.800best.com/fin/jdk7-tomcat8:0.0.2

LABEL app="bdc-vkereg"

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

ENV JAVA_OPTS="-Dfile.encoding=UTF-8"
ENV CATALINA_OPTS="-XX:PermSize=128m -XX:MaxPermSize=512m -Xms512m -Xmx1024m"
ENV JPDA_ADDRESS=5005
ENV JPDA_TRANSPORT=dt_socket

COPY server/flex/war/target/bdc-flex-war.war ${CATALINA_HOME}/webapps/bdc-flex-war.war

WORKDIR ${CATALINA_HOME}

EXPOSE 8080 5005

CMD ["bin/catalina.sh", "jpda", "run"]
