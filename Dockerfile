FROM node:9.11.1-alpine

MAINTAINER Andy Savage <andy@savage.hk>

LABEL org.label-schema.name="google-group-crawler" \
      org.label-schema.description="Docker Image to handle downloading attachment files from Google Groups and sending to an AMQP queue" \
      org.label-schema.vcs-url="https://github.com/hongkongkiwi/google-group-crawler" \
      org.label-schema.license="MIT"

# This is some stuff required for runit to work
STOPSIGNAL SIGCONT

ENV SERVICE_AVAILABLE_DIR=/etc/sv \
    SERVICE_ENABLED_DIR=/service \
    SVDIR=${SERVICE_ENABLED_DIR} \
    SVWAIT=7

ENV SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/v0.1.5/supercronic-linux-amd64" \
    SUPERCRONIC='supercronic-linux-amd64' \
    SUPERCRONIC_SHA1SUM=9aeb41e00cc7b71d30d33c57a2333f2c2581a201

ENV RUNIT_INSTALL_SCRIPT="https://rawgit.com/dockage/runit-scripts/master/scripts/installer"

ENV GOOGLE_CRAWLER_REPO='https://github.com/icy/google-group-crawler.git'
#ENV QUICK_LOCK_REPO='https://raw.githubusercontent.com/oresoftware/quicklock/master/install.sh'
ENV QUICK_LOCK_REPO='https://raw.githubusercontent.com/hongkongkiwi/quicklock/master/install.sh'

# Some options that can be configured
ENV CRON_SCHEDULE='*/30 * * * *'
ENV COOKIES_FILE='/config/cookies.txt'
ENV HOOK_FILE='/google-group-crawler/hook.sh'
ENV GOOGLE_GROUP_NAME=''
ENV GOOGLE_GROUP_ORG=''
ENV UPDATE_MESSAGE_COUNT=50
ENV FORCE_REFRESH='false'
ENV DOWNLOAD_ATTACHMENTS='true'
ENV PULL_ON_BOOT='true'
ENV TZ='Asia/Hong_Kong'
ENV NPM_CONFIG_LOGLEVEL='error'

ENV AMQP_ENABLED='false'
ENV AMQP_TOPIC='google_groups_changes'
ENV AMQP_SERVER=''
ENV AMQP_USER=''
ENV AMQP_PASS=''
ENV AMQP_VHOST=''

VOLUME ["/data", "/config"]

# We need to set work directory as this is where the crawler will save the data
WORKDIR /data

COPY scripts/sync-google-group "/usr/bin/sync-google-group"
COPY scripts/send-amqp-message "/usr/bin/send-amqp-message"
COPY start-container.sh "/start-container.sh"

# install dependencies
RUN echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
 # Add community repo
 && apk update \
 && apk add --upgrade apk-tools@edge \
 # Install these as a group so they are easy to remove
 && apk add --no-cache --virtual .build-dependencies \
        curl \
        git \
        tzdata \
        gcc \
 && apk add --no-cache \
        runit \
        ca-certificates \
        tini \
        bash gawk sed grep wget coreutils procps \
        rabbitmq-c-utils \
        python3 \
        python3-dev \
        yaml-dev \
        musl-dev \
        ripmime@edgecommunity \
# Set the time
 && echo "Setting Time Zone" \
 && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
 && echo "${TZ}" > /etc/timezone
# install supercronic
# (from https://github.com/aptible/supercronic/releases)
RUN echo "Installing Supercronic" \
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM} ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
# Download Google Group Crawler bash scripts
RUN echo "Installing Google Group Crawler" \
 && ([ -d /google-group-crawler ] && rm -Rf /google-group-crawler || true) \
 && git clone -q "${GOOGLE_CRAWLER_REPO}" /google-group-crawler
# Install One Lock scripts
RUN echo "Installing Quicklook Repo" \
 && curl -o- "${QUICK_LOCK_REPO}" | bash
# Upgrade PIP
RUN echo "Upgrading Pip & Installing Watchdog" \
 && pip3 install --no-cache-dir --upgrade pip \
 && pip3 install --no-cache-dir watchdog
RUN echo "Installing Runit" \
 && cd / \
 && curl --output /runit_installer -fsSLO "$RUNIT_INSTALL_SCRIPT" \
 && mkdir -p "${SERVICE_AVAILABLE_DIR}" "${SERVICE_ENABLED_DIR}" \
 && chmod +x /runit_installer \
 && /runit_installer \
 && cd /data
COPY runit/ "${SERVICE_AVAILABLE_DIR}/"
RUN ln -s "${SERVICE_AVAILABLE_DIR}/supercronic" "${SERVICE_ENABLED_DIR}" \
 && ln -s "${SERVICE_AVAILABLE_DIR}/watchdog" "${SERVICE_ENABLED_DIR}" \
 && mkdir -p "/var/log/supercronic" "/var/log/watchdog"

# Create expected directories
RUN echo "Setting Things Up" \
 && chmod +x "/usr/bin/send-amqp-message" \
 && chmod +x "/usr/bin/sync-google-group" \
 && chmod +x /start-container.sh \
 && echo "${CRON_SCHEDULE} /usr/bin/sync-google-group" > /etc/crontab

# clean up dependencies
RUN echo "Cleaning Up" \
 && apk del --purge .build-dependencies \
 && rm -rf /var/cache/apk/* \
 && rm -rf ~/.cache/pip \
 && rm -rf /runit_installer /dockage-runit-scripts-*

COPY hook.sh /google-group-crawler/hook.sh

ENTRYPOINT ["/sbin/runit-init"]
