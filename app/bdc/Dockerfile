FROM jdk7-base

LABEL app="bdc"

# 设置 Java 默认编码为 UTF-8
ENV JAVA_OPTS="-Dfile.encoding=UTF-8"
ENV CATALINA_OPTS="-XX:PermSize=128m -XX:MaxPermSize=512m -Xms512m -Xmx1024m"

ENV JPDA_ADDRESS=5005
ENV JPDA_TRANSPORT=dt_socket

CMD ["catalina.sh", "jpda", "run"]
