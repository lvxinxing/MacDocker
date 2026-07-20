# 固定 amd64（Apple Silicon 必须）
FROM --platform=linux/amd64 quay.io/centos/centos:7

LABEL maintainer="local-dev-jdk7"

# -------------------------------------------------
# 1. 修复 CentOS 7 yum 仓库（内联，最稳）
# -------------------------------------------------
RUN rm -f /etc/yum.repos.d/*.repo && \
    cat > /etc/yum.repos.d/CentOS-Vault.repo << 'EOF'
[base]
name=CentOS-7 - Base
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/
enabled=1
gpgcheck=0

[updates]
name=CentOS-7 - Updates
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/
enabled=1
gpgcheck=0

[extras]
name=CentOS-7 - Extras
baseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/
enabled=0
gpgcheck=0
EOF

# -------------------------------------------------
# 2. 基础依赖
# -------------------------------------------------
RUN yum clean all && yum makecache && \
    yum install -y \
        tar \
        gzip \
        wget \
        unzip \
        which \
        tzdata \
        fontconfig \
        freetype \
    && yum clean all

# -------------------------------------------------
# 3. 时区
# -------------------------------------------------
ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# -------------------------------------------------
# 4. JDK 7（Zulu，严谨解压）
# -------------------------------------------------
ENV JAVA_HOME=/usr/local/java
ENV PATH=${JAVA_HOME}/bin:${PATH}

COPY jdk/zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz /usr/local/

RUN cd /usr/local && \
    tar -zxf zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz && \
    JDK_DIR=$(tar -tf zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz | head -1 | cut -d/ -f1) && \
    mv "$JDK_DIR" java && \
    rm -f zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz

# -------------------------------------------------
# 5. Tomcat 7
# -------------------------------------------------
ENV CATALINA_HOME=/usr/local/tomcat
ENV PATH=${CATALINA_HOME}/bin:${PATH}

COPY tomcat/apache-tomcat-7.0.109.tar.gz /usr/local/

RUN cd /usr/local && \
    tar -zxf apache-tomcat-7.0.109.tar.gz && \
    TOMCAT_DIR=$(tar -tf apache-tomcat-7.0.109.tar.gz | head -1 | cut -d/ -f1) && \
    mv "$TOMCAT_DIR" tomcat && \
    rm -rf tomcat/webapps/* apache-tomcat-7.0.109.tar.gz

# -------------------------------------------------
# 6. Maven（JDK7 兼容，用于 bpg-new）
# -------------------------------------------------
ENV MAVEN_HOME=/usr/local/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}

COPY mvn/apache-maven-3.2.5-bin.tar.gz /usr/local/

RUN cd /usr/local && \
    tar -zxf apache-maven-3.2.5-bin.tar.gz && \
    MAVEN_DIR=$(tar -tf apache-maven-3.2.5-bin.tar.gz | head -1 | cut -d/ -f1) && \
    mv "$MAVEN_DIR" maven && \
    rm -f apache-maven-3.2.5-bin.tar.gz

EXPOSE 8080 5005

CMD ["catalina.sh", "run"]
