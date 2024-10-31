#!/bin/bash

[[ -z $JF_PORT ]] && JF_PORT=8096
[[ -z $JF_URL ]] && JF_URL="http://localhost:${JF_PORT}"
[[ -z $JF_HEALTHCHECK_URL ]] && JF_HEALTHCHECK_URL="${JF_URL}/health"
[[ -z $JF_WAIT_COUNTER_MAX ]] && WAIT_COUNTER_MAX=$((60 * 4))
WAIT_COUNTER=0

check_health() {
  curl --location --insecure --fail --silent "${JF_HEALTHCHECK_URL}"
}

if ! check_health; then
  notify-send 2> /dev/null "Jellyfin" "Server is starting, monitoring health check URL."

  exec jellyfin "$@" &

  # Health check
  until [[ ${WAIT_COUNTER} -gt ${WAIT_COUNTER_MAX} ]]; do

    [[ "$(check_health)" == "Healthy" ]] && break

    sleep 0.25
    ((WAIT_COUNTER++))
  done

  if [[ ${WAIT_COUNTER} -ge ${WAIT_COUNTER_MAX} ]]; then
    notify-send 2> /dev/null "Jellyfin" "Application is not responding."
    exit 1
  else
    notify-send 2> /dev/null "Jellyfin" "Startup completed after $((WAIT_COUNTER / 4)) seconds."
    xdg-open "${JF_URL}"
  fi
else
  xdg-open "${JF_URL}"
fi
