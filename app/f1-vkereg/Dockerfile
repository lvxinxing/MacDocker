FROM --platform=linux/amd64 vkereg.800best.com/bestbase/besttomcat7:jre7-python3

LABEL app="f1-vkereg"

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" > /etc/timezone

COPY server/flex/war/target/f1-flex-war.war /usr/local/tomcat/webapps/f1-flex-war.war

ENV JAVA_OPTS=${JAVA_OPTS}

EXPOSE 8080 5005

CMD ["catalina.sh", "run"]
