#!/usr/bin/env bash

. "/root/.quicklock/ql.sh"

ql_acquire_lock "run.sh"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$COOKIES_FILE" ] && echo "Need to set COOKIES_FILE environment variable" && exit 1;
[ ! -f "$COOKIES_FILE" ] && echo "Cookies file is blank!" && exit 1;
[ -z "$GOOGLE_GROUP_NAME" ] && echo "Need to set GOOGLE_GROUP_NAME environment variable" && exit 1;
[ -z "$GOOGLE_GROUP_ORG" ] && echo "Need to set GOOGLE_GROUP_ORG environment variable" && exit 1;

export _WGET_OPTIONS="--load-cookies ${COOKIES_FILE} --keep-session-cookies -nv"
export _GROUP="$GOOGLE_GROUP_NAME"
export _ORG="$GOOGLE_GROUP_ORG"
export _HOOK_FILE="/google-group-crawler/hook.sh"
[[ "$FORCE_REFRESH" == "true" ]] && export _FORCE="true"
export _RSS_NUM=$UPDATE_MESSAGE_COUNT

if [[ -f "/etc/firstrun" ]] && [[ ! -d "/data/$_GROUP" ]];  then
  echo "Invalid data directory! Restarting first run..."
  rm "/etc/firstrun"
fi

if [[ ! -f "/etc/firstrun" ]]; then
  echo "First run detected!" && \
  "/google-group-crawler/crawler.sh" -sh && \
  "/google-group-crawler/crawler.sh" -sh > "/google-group-crawler/wget.sh" && \
  bash "/google-group-crawler/wget.sh" && \
  touch "/etc/firstrun"
else
  echo "Updating Messages!" && \
  #rm -fv /data/$_GROUP/threads/t.* && \
  #rm -fv /data/$_GROUP/msgs/m.* && \
  "/google-group-crawler/crawler.sh" -rss > "/google-group-crawler/update.sh"
  bash "/google-group-crawler/update.sh"
fi
