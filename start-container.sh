#!/usr/bin/env bash

if [[ "$PULL_ON_BOOT" == 'true' ]]; then
  "/run.sh"
fi
"/usr/local/bin/supercronic" "/etc/crontab"
