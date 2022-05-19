FROM jenkins/jenkins:lts-alpine-jdk11

# copy plugins list and install them
COPY --chown=jenkins:jenkins jenkins/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# copy initial build job as an example
COPY --chown=jenkins:jenkins jenkins/jobs/ /var/jenkins_home/jobs/
