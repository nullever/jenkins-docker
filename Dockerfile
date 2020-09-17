FROM openjdk:8-alpine AS jenkins

RUN apk add --no-cache \
  bash \
  coreutils \
  curl \
  git \
  git-lfs \
  openssh-client \
  tini \
  ttf-dejavu \
  tzdata \
  unzip

ARG JENKINS_USER
ARG JENKINS_GROUP
ARG JENKINS_UID
ARG JENKINS_GID
ARG JENKINS_REF
ARG JENKINS_HOME
ARG JENKINS_SHA
ARG JENKINS_URL
ARG PLUGIN_CLI_URL

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p ${JENKINS_HOME} \
  && chown ${JENKINS_UID}:${JENKINS_GID} ${JENKINS_HOME} \
  && addgroup -g ${JENKINS_GID} ${JENKINS_GROUP} \
  && adduser -h "${JENKINS_HOME}" -u ${JENKINS_UID} -G ${JENKINS_GROUP} -s /bin/bash -D ${JENKINS_USER}

# $JENKINS_REF (defaults to `/usr/share/jenkins/ref/`) contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p ${JENKINS_REF}/init.groovy.d

RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

RUN chown -R ${JENKINS_USER} "${JENKINS_HOME}" "${JENKINS_REF}"

RUN curl -fsSL ${PLUGIN_CLI_URL} -o /usr/lib/jenkins-plugin-manager.jar

USER ${JENKINS_USER}

# from a derived Dockerfile, can use `RUN install-plugins.sh active.txt` to setup $REF/plugins from a support bundle
COPY /tools/install-plugins.sh /usr/local/bin/install-plugins.sh
COPY /tools/jenkins-support /usr/local/bin/jenkins-support
COPY /tools/jenkins.sh /usr/local/bin/jenkins.sh
COPY /tools/tini-shim.sh /bin/tini
COPY /tools/jenkins-plugin-cli.sh /bin/jenkins-plugin-cli

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
