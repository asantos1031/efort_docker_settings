FROM ubuntu:18.04
MAINTAINER Bamboo/Atlassian

ENV BAMBOO_VERSION=6.8.2

ENV DOWNLOAD_URL=https://packages.atlassian.com/maven-closedsource-local/com/atlassian/bamboo/atlassian-bamboo-agent-installer/${BAMBOO_VERSION}/atlassian-bamboo-agent-installer-${BAMBOO_VERSION}.jar
ENV BAMBOO_USER=bamboo
ENV BAMBOO_GROUP=bamboo
ENV BAMBOO_USER_HOME=/home/${BAMBOO_USER}
ENV BAMBOO_AGENT_HOME=${BAMBOO_USER_HOME}/bamboo-agent-home
ENV AGENT_JAR=${BAMBOO_USER_HOME}/atlassian-bamboo-agent-installer.jar
ENV SCRIPT_WRAPPER=${BAMBOO_USER_HOME}/runAgent.sh
ENV INIT_BAMBOO_CAPABILITIES=${BAMBOO_USER_HOME}/init-bamboo-capabilities.properties
ENV BAMBOO_CAPABILITIES=${BAMBOO_AGENT_HOME}/bin/bamboo-capabilities.properties

RUN apt-get update -y  \
    && apt-get upgrade -y \
    # please keep Java version in sync with JDK capabilities below
    && apt-get install -y openjdk-8-jdk \
    && apt-get install -y curl

#Install dotnet
RUN apt-get install sudo \
    && sudo apt-get install software-properties-common -y\
    && sudo apt-get update -y\
    && sudo apt-get upgrade -y\
    && sudo apt-get install wget -y \
    && sudo apt-get install gpg-agent -y 

 RUN   curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-bionic-prod bionic main" > /etc/apt/sources.list.d/dotnetdev.list' \
    && sudo apt-get install apt-transport-https \
    && sudo apt-get update \
    && sudo apt-get install dotnet-sdk-2.2 -y 

#Install firefox (iceweasel)
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install iceweasel -y 

#Install geckodriver V0.24 for linux
RUN wget -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.24.0/geckodriver-v0.24.0-linux64.tar.gz \
    && tar -C /opt -zxf /tmp/geckodriver.tar.gz \
    && rm /tmp/geckodriver.tar.gz 

# install necessary locales
RUN apt-get install -y locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen

RUN apt-get install unzip

#Install MSSQL
COPY sqlpackage-linux-x64-150.4384.2.zip /tmp
COPY mssql_install.sh /tmp

RUN chmod +x /tmp/mssql_install.sh \
	&& /tmp/mssql_install.sh 

RUN echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/16.04/prod xenial main" | sudo tee /etc/apt/sources.list.d/mssql.list \
    && sudo apt install libcurl3 -y \
    && sudo apt-get install systemd -y \
    && apt-get install -y curl 

RUN chmod +x /opt/mssql/bin/sqlservr

RUN sudo apt-get install lsof \
	&& sudo apt-get install redis-server -y

RUN nohup redis-server&

RUN addgroup ${BAMBOO_GROUP} && \
     adduser --home ${BAMBOO_USER_HOME} --ingroup ${BAMBOO_GROUP} --disabled-password ${BAMBOO_USER}

RUN curl -L --output ${AGENT_JAR} ${DOWNLOAD_URL}
COPY bamboo-update-capability.sh  ${BAMBOO_USER_HOME}/bamboo-update-capability.sh 
COPY runAgent.sh ${SCRIPT_WRAPPER} 

RUN chmod +x ${BAMBOO_USER_HOME}/bamboo-update-capability.sh && \
    chmod +x ${SCRIPT_WRAPPER} && \
    mkdir -p ${BAMBOO_USER_HOME}/bamboo-agent-home/bin

RUN chown -R ${BAMBOO_USER} ${BAMBOO_USER_HOME}

USER ${BAMBOO_USER}

RUN ${BAMBOO_USER_HOME}/bamboo-update-capability.sh "system.jdk.JDK 1.8" /usr/lib/jvm/java-1.8-openjdk/bin/java

WORKDIR ${BAMBOO_USER_HOME}

ENTRYPOINT ["./runAgent.sh"]