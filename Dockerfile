FROM node:9.11.1-alpine

MAINTAINER Andy Savage <andy@savage.hk>

LABEL org.label-schema.name="google-group-crawler" \
      org.label-schema.description="Docker Image to handle downloading attachment files from Google Groups and sending to an AMQP queue" \
      org.label-schema.vcs-url="https://github.com/hongkongkiwi/google-group-crawler" \
      org.label-schema.license="MIT"

# This is some stuff required for runit to work
STOPSIGNAL SIGCONT

ARG SERVICE_AVAILABLE_DIR="/etc/sv"
ARG SERVICE_ENABLED_DIR="/service"
ARG SVDIR="${SERVICE_ENABLED_DIR}"
ARG SVWAIT=7

ARG OS="linux"
ARG ARCH="amd64"

# URLS for stuff to install during build
ARG SUPERCRONIC_VER="0.1.5"
ARG SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VER}/supercronic-${OS}-${ARCH}"
ARG SUPERCRONIC="supercronic-${OS}-${ARCH}"
ARG SUPERCRONIC_SHA1SUM='9aeb41e00cc7b71d30d33c57a2333f2c2581a201'
ARG RUNIT_INSTALL_SCRIPT='https://rawgit.com/dockage/runit-scripts/master/scripts/installer'
ARG GOOGLE_CRAWLER_REPO='https://github.com/icy/google-group-crawler.git'
ARG QUICK_LOCK_REPO='https://raw.githubusercontent.com/oresoftware/quicklock/master/install.sh'
    #QUICK_LOCK_REPO='https://raw.githubusercontent.com/hongkongkiwi/quicklock/master/install.sh'
ARG RCLONE_VER="current"
ARG RCLONE_URL="https://downloads.rclone.org/rclone-${RCLONE_VER}-${OS}-${ARCH}.zip"
ARG LEVELDB_REPO='https://github.com/0x00a/ldb.git'
ARG BLOG_URL='https://raw.githubusercontent.com/idelsink/b-log/master/b-log.sh'

# Some options that can be configured
ENV CRON_SCHEDULE='*/30 * * * *'
# Which files do we want to trigger our hook on
ENV WATCH_FILE_PATTERN='*.xls'
# Where we can find the cookies file for authing to google groups
ENV COOKIES_FILE='/config/cookies.txt'
# You shouldn't need to change this unless you want to change the hook script
ENV HOOK_FILE='/google-group-crawler/hook.sh'
ENV GOOGLE_GROUP_NAME=''
# This is important when dealing with Google Group in organisation
ENV GOOGLE_GROUP_ORG=''
# How many messages to get when updating via RSS
ENV UPDATE_MESSAGE_COUNT=50
# Set this to force pull down all messages
ENV FORCE_REFRESH='false'
# If you only want messages you can change this
ENV DOWNLOAD_ATTACHMENTS='true'
# This will produce a lot of noise and is not recommended unless you need a full pull
ENV PULL_ON_BOOT='true'
# Mostly useful for the cron script
ENV TZ='Asia/Hong_Kong'

# Ignore the noisy NPM installs
ENV NPM_CONFIG_LOGLEVEL='error'

# Upload files we find to rclone remote (e.g. Google Groups)
ENV RCLONE_UPLOAD='true'
# Which rclone remote to upload to
ENV RCLONE_REMOTE='Google Drive'

# Send files found to AQMP server?
ENV AMQP_ENABLED='false'
# AMQP Server info
ENV AMQP_URL=''
ENV AMQP_EXCHANGE='google_groups'
ENV AMQP_QUEUE='google_groups_changes'

# Path to Python (required for some NPM builds)
ENV PYTHON="/usr/bin/python"
# Path to b-log.sh which is downloaded for bash logging
ENV BLOG="/usr/local/include/b-log.sh"

VOLUME ["/data", "/config"]

# We need to set work directory as this is where the crawler will save the data
WORKDIR /data

# Copy all our awesome scripts to the bin
COPY scripts/* /usr/local/bin/

# install dependencies
RUN echo "@edgecommunity http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && echo "@edgetesting http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
 && echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
 # Add community repo
 && apk update \
 && apk add --upgrade apk-tools@edge \
 # Install these as a group so they are easy to remove
 && apk add --no-cache --virtual .build-dependencies \
        cmake@edge \
        unzip \
        curl \
        git \
        tzdata \
        py2-pip \
        make g++ snappy-dev gcc \
 && apk add cmake@edge \
 && apk add --no-cache \
        netcat-openbsd \
        snappy \
        runit \
        ca-certificates \
        tini \
        bash gawk sed grep wget coreutils procps \
        rabbitmq-c-utils \
        python3 \
        python3-dev \
        python \
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
 && ln -s "/usr/local/bin/${SUPERCRONIC}" "/usr/local/bin/supercronic"

# Download Google Group Crawler bash scripts
RUN echo "Installing Google Group Crawler" \
 && ([ -d /google-group-crawler ] && rm -Rf /google-group-crawler || true) \
 && git clone -q "${GOOGLE_CRAWLER_REPO}" /google-group-crawler

# Install One Lock scripts
RUN echo "Installing Quicklook Repo" \
 && curl -o- "${QUICK_LOCK_REPO}" | bash

# Upgrade PIP
RUN echo "Upgrading Pip & Installing Watchdog" \
 && pip3 install -q --no-cache-dir --upgrade pip \
 && pip3 install -q --no-cache-dir watchdog \
 && pip2 install -q --no-cache-dir crudini

 # Install Runit
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
 && ln -s "${SERVICE_AVAILABLE_DIR}/sync-google-group-oneshot" "${SERVICE_ENABLED_DIR}" \
 && mkdir -p "/var/log/supercronic" "/var/log/watchdog"

# Install rclone
RUN echo "Installing rclone" \
 && mkdir -p /tmp \
 && cd /tmp \
 && wget -q "${RCLONE_URL}" \
 && unzip -qq /tmp/rclone-*.zip \
 && mv /tmp/rclone-*-${OS}-*/rclone /usr/local/bin \
 && mkdir -p /var/lock \
 && touch /var/lock/rclone.lock \
 && cd /data

# LevelDB for Shell
RUN echo "Installing LevelDB" \
 && mkdir -p "/usr/share/man/man1" \
 && git clone -q "${LEVELDB_REPO}" /tmp/ldb \
 && cd /tmp/ldb \
 && make && make install

# Installing Logging Libraries
RUN echo "Installing Additional Shell Libraries" \
 && mkdir -p "/usr/local/include" \
 && wget -q -O "${BLOG}" "${BLOG_URL}"

# Create expected directories
RUN echo "Setting Things Up" \
 && chmod +x /usr/local/bin/* \
 && echo "${CRON_SCHEDULE} /usr/local/bin/sync-google-group" > /etc/crontab

# clean up dependencies
RUN echo "Cleaning Up" \
 && apk del --purge .build-dependencies \
 && rm -rf /var/cache/apk/* \
 && rm -rf /tmp/* /var/tmp/* \
 && rm -rf ~/.cache/pip \
 && rm -rf /runit_installer /dockage-runit-scripts-*

COPY hook.sh "$HOOK_FILE"

WORKDIR /data

ENTRYPOINT ["/sbin/runit-init"]
