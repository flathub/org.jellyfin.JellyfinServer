#!/bin/bash

[[ -z "${JF_PORT}" ]] && JF_PORT=8096
[[ -z "${JF_PORT_HTTPS}" ]] && JF_PORT_HTTPS=8920
[[ -z "${JF_URL}" ]] && JF_URL="http://localhost:${JF_PORT}"
[[ -z "${JF_HEALTHCHECK_URL}" ]] && JF_HEALTHCHECK_URL="${JF_URL}/health"
[[ -z "${JF_WAIT_COUNTER_MAX}" ]] && JF_WAIT_COUNTER_MAX=$((60 * 4))

# Use Tailscale Magic DNS with HTTPS when $TS_SELF_DNS_NAME and
# $TS_USE_MAGIC_DNS have been set by the user.
[[ -n "${TS_SELF_DNS_NAME}" && "${TS_USE_MAGIC_DNS}" == "true" ]] && JF_URL="https://${TS_SELF_DNS_NAME}:${JF_PORT_HTTPS}"

# Start with 1 (250mc) instead of 0, this is typically closer to what is reported
# in the log.
WAIT_COUNTER=1
TS_CERT_CRT="/var/config/jellyfin/${TS_SELF_DNS_NAME}.crt"
TS_CERT_KEY="/var/config/jellyfin/${TS_SELF_DNS_NAME}.key"
TS_CERT_PFX="/var/config/jellyfin/ts-web-certificate.pfx"

check_health() {
  # These curl parameters have been taken from Jellyfin build scripts and
  # turned into their respective long forms to improve readabilility.
  curl --location --insecure --fail --silent "${JF_HEALTHCHECK_URL}"
}

[[ "$1" == "backup" ]] && {
  "jf-backup.sh"
  exit
}
[[ "$1" == "updater" ]] && {
  "jf-updater.sh"
  exit
}

if [[ -n "${TS_SELF_DNS_NAME}" && -f "${TS_CERT_CRT}" && -f "${TS_CERT_KEY}" ]]; then
  # TODO: Notify how long certificate is valid.
  echo "Found Tailscale certficates."
  openssl pkcs12 \
    -export \
    -out "${TS_CERT_PFX}" \
    -inkey "${TS_CERT_KEY}" \
    -in "${TS_CERT_CRT}" \
    -passout pass: \
    && echo "Converted Tailscale certficates."
fi

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
