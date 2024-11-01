#!/bin/bash

[[ -z "${JF_PORT}" ]] && JF_PORT=8096
[[ -z "${JF_URL}" ]] && JF_URL="http://localhost:${JF_PORT}"
[[ -z "${JF_HEALTHCHECK_URL}" ]] && JF_HEALTHCHECK_URL="${JF_URL}/health"
[[ -z "${JF_WAIT_COUNTER_MAX}" ]] && JF_WAIT_COUNTER_MAX=$((60 * 4))
# Start with 1 (250mc) instead of 0, this is usually closer to what is reported
# in the log.
WAIT_COUNTER=1

check_health() {
  # These curl parameters have been taken from Jellyfin build scripts and
  # turned into their respective long forms to improve readabilility.
  curl --location --insecure --fail --silent "${JF_HEALTHCHECK_URL}"
}

if ! check_health; then
  notify-send 2> /dev/null "Jellyfin" "Server is starting, monitoring health check URL."

  # Start the server application, with parameters if provided.
  exec jellyfin "$@" &

  # Perform health check to determine when the application is ready without
  # checking the log.
  until [[ ${WAIT_COUNTER} -gt ${JF_WAIT_COUNTER_MAX} ]]; do

    [[ "$(check_health)" == "Healthy" ]] && break

    # A quarter of a second should be a good compromise between sufficient
    # granularity and script complexity.
    sleep 0.25

    ((WAIT_COUNTER++))
  done

  if [[ ${WAIT_COUNTER} -ge ${JF_WAIT_COUNTER_MAX} ]]; then
    notify-send 2> /dev/null "Jellyfin" "Application is not responding."
    exit 1
  else
    # Allow up to 750ms of under reporting the startup time in seconds here as
    # bash only returns integers.
    notify-send 2> /dev/null "Jellyfin" "Startup completed after $((WAIT_COUNTER / 4)) seconds."

    # Only open the web interface the application is not started as a service.
    [[ ! "$*" =~ ("--service") ]] && xdg-open "${JF_URL}"
  fi
else
  notify-send 2> /dev/null "Jellyfin" "Another instance is already runnng."

  # Attempt to open the dashboard with direct access to restart and shutdown
  # options.
  xdg-open "${JF_URL}/web/#/dashboard"
fi
