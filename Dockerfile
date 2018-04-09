FROM istepanov/cron

ENV CRON_SCHEDULE '0 * * * *'
ENV COOKIES_FILE '/data/cookies.txt'
ENV GOOGLE_GROUP_NAME ''
ENV GOOGLE_GROUP_ORG ''
ENV _HOOK_FILE="/google-group-crawler/hook.sh"

COPY "./hook.sh" "/google-group-crawler/hook.sh"

RUN apk add --no-cache bash gawk sed grep bc coreutils ca-certificates wget git ripmime && \
    mkdir "/data" && \
    rm -Rf "/google-group-crawler" && \
    git clone -q "https://github.com/icy/google-group-crawler.git" "/google-group-crawler" && \
    apk del wget ca-certificates
