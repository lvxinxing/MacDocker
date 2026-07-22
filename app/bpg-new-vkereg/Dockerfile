FROM --platform=linux/amd64 vkereg.800best.com/bestbase/besttomcat7:jre7-python3

LABEL app="bpg-new-vkereg"

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo "Asia/Shanghai" > /etc/timezone

ENV JAVA_OPTS="-Dfile.encoding=UTF-8"
ENV CATALINA_OPTS="-XX:PermSize=128m -XX:MaxPermSize=512m -Xms512m -Xmx1024m"
ENV JPDA_ADDRESS=5005
ENV JPDA_TRANSPORT=dt_socket

RUN rm -rf /usr/local/tomcat/webapps/*

COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

WORKDIR /usr/local/tomcat

EXPOSE 8080 5005

CMD ["catalina.sh", "jpda", "run"]
