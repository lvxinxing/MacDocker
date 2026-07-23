FROM jdk7-base

LABEL app="bpg-new"

# 设置 Java 默认编码为 UTF-8
ENV JAVA_OPTS="-Dfile.encoding=UTF-8"
# 设置 Maven 和 Catalina 的 JVM 参数
ENV MAVEN_OPTS="-Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=512m"
ENV CATALINA_OPTS="-XX:PermSize=128m -XX:MaxPermSize=512m -Xms512m -Xmx1024m"

# 设置工作目录
WORKDIR /workspace

# 清除 Tomcat 的默认 web 应用
RUN rm -rf /usr/local/tomcat/webapps/*

# 设置 JPDA 的参数
ENV JPDA_ADDRESS=5005
ENV JPDA_TRANSPORT=dt_socket

# CMD 命令：先编译，然后将 WAR 文件复制到 Tomcat 中并运行
CMD ["bash", "-c", "\
  mvn -s /root/.m2/settings.xml clean package -DskipTests && \
  cp bpg-new/target/*.war /usr/local/tomcat/webapps/bpg-new.war && \
  /usr/local/tomcat/bin/catalina.sh jpda run \
"]