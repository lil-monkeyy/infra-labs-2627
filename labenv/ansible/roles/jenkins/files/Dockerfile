FROM jenkins/jenkins:lts-jdk21

# Extra tools voor de deploy-stappen (rsync zit niet standaard in het image)
USER root
ARG COMPOSE_VERSION=v2.26.1
RUN apt-get update \
 && apt-get install -y --no-install-recommends rsync docker.io \
 && rm -rf /var/lib/apt/lists/*

 #docker compose plugin installeren via de CLI (zie probleem labo CICD)
RUN mkdir -p /usr/local/lib/docker/cli-plugins \
 && curl -fSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose \
 && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose 
USER jenkins

# Setup-wizard uitschakelen
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Plugins installeren
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# JCasC-configuratie
COPY --chown=jenkins:jenkins jenkins.yml /var/jenkins_conf/jenkins.yml
ENV CASC_JENKINS_CONFIG=/var/jenkins_conf/jenkins.yml