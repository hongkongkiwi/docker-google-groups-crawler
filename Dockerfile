FROM alpine:latest

ENV SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/v0.1.5/supercronic-linux-amd64" \
    SUPERCRONIC='supercronic-linux-amd64' \
    SUPERCRONIC_SHA1SUM=9aeb41e00cc7b71d30d33c57a2333f2c2581a201

ENV GOOGLE_CRAWLER_REPO='https://github.com/icy/google-group-crawler.git'
ENV QUICK_LOCK_REPO='https://raw.githubusercontent.com/oresoftware/quicklock/master/install.sh'

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

VOLUME ["/data", "/config"]

# We need to set work directory as this is where the crawler will save the data
WORKDIR /data

COPY run.sh /run.sh
COPY start-container.sh "/start-container.sh"

# install dependencies
RUN apk update \
 && apk add --no-cache \
        tzdata \
        ca-certificates \
        curl \
        tini \
        bash gawk sed grep wget coreutils procps \
        git \
        ripmime \
# Set the time
 && cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
 && echo "${TZ}" >  /etc/timezone \
# install supercronic
# (from https://github.com/aptible/supercronic/releases)
 && curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic \
# Download Google Group Crawler bash scripts
 && ([ -d /google-group-crawler ] && rm -Rf /google-group-crawler || true) \
 && git clone -q "${GOOGLE_CRAWLER_REPO}" /google-group-crawler \
# Install One Lock scripts
 && curl -o- "${QUICK_LOCK_REPO}" | bash \

# Create expected directories
 && chmod +x /run.sh \
 && chmod +x /start-container.sh \
 && echo "${CRON_SCHEDULE} /run.sh" > /etc/crontab \
# clean up dependencies
 && apk del --purge \
         curl \
         git \
         tzdata \
 && rm -rf /var/cache/apk/

COPY hook.sh /google-group-crawler/hook.sh

ENTRYPOINT [ "/sbin/tini", "--" ]

CMD [ "/start-container.sh" ]
