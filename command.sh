#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[ -z "$COOKIES_FILE" ] && echo "Need to set COOKIES_FILE environment variable" && exit 1;
[ !-f "$COOKIES_FILE" ] && echo "Cookies file is blank!" && exit 1;
[ -z "$GOOGLE_GROUP_NAME" ] && echo "Need to set GOOGLE_GROUP_NAME environment variable" && exit 1;
[ -z "$GOOGLE_GROUP_ORG" ] && echo "Need to set GOOGLE_GROUP_ORG environment variable" && exit 1;
[ -z "$_HOOK_FILE" ] && echo "Need to set _HOOK_FILE environment variable" && exit 1;

export _WGET_OPTIONS="--load-cookies ${COOKIES_FILE} --keep-session-cookies"
export _GROUP="$GOOGLE_GROUP_NAME"
export _ORG="$GOOGLE_GROUP_ORG"
export _HOOK_FILE="$_HOOK_FILE"

"/google-group-crawler/crawler.sh" -sh
