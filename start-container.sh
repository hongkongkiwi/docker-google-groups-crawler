#!/usr/bin/env bash

if [[ "$PULL_ON_BOOT" == 'true' ]]; then
  "/run.sh"
fi
echo "${CRON_SCHEDULE} /run.sh" > "/etc/crontab" && \
"/usr/local/bin/supercronic" "/etc/crontab"
