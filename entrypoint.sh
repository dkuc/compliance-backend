#!/bin/bash

set -e

function is_puma_installed() {
  [ ! -f Gemfile.lock ] && return 1
  grep ' puma ' Gemfile.lock >/dev/null
}

function check_number() {
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "$1 needs to be a non-negative number"
    exit 1
  fi
}

source "scripts/lib/clowder-common-bash/src/clowder-config-main.sh"

if [ -z "$APPLICATION_TYPE" ]; then
  echo "APPLICATION_TYPE not defined!"
  exit 1
fi

if isClowderEnabled; then
  PROMETHEUS_EXPORTER_PORT="$(ClowderConfigMetricsPort)"
  export PROMETHEUS_EXPORTER_PORT
fi

if [ "$APPLICATION_TYPE" = "compliance-backend" ]; then
  check_number PUMA_WORKERS     "${PUMA_WORKERS:-0}"
  check_number PUMA_MIN_THREADS "${PUMA_MIN_THREADS:-0}"
  check_number PUMA_MAX_THREADS "${PUMA_MAX_THREADS:-0}"

  export RACK_ENV=${RACK_ENV:-"production"}

  if isClowderEnabled; then
    PORT=$(ClowderConfigWebPort)
  else
    PORT="8080"
  fi

  if is_puma_installed; then
    exec bundle exec "puma --config ./config/puma.cfg -b tcp://0.0.0.0:${PORT}"
  else

    echo "You might consider adding 'puma' into your Gemfile."

    if bundle exec rackup -h &>/dev/null; then
      if [ -f Gemfile ]; then
        exec bundle exec "rackup -E ${RAILS_ENV:-$RACK_ENV} -P /tmp/rack.pid --host 0.0.0.0 --port ${PORT}"
      else
        exec rackup -E "${RAILS_ENV:-$RACK_ENV}" -P /tmp/rack.pid --host 0.0.0.0 --port "${PORT}"
      fi
    else
      echo "ERROR: Rubygem Rack is not installed in the present image."
      echo "       Add rack to your Gemfile in order to start the web server."
    fi
  fi
elif [ "$APPLICATION_TYPE" = "compliance-inventory" ]; then
  exec bundle exec racecar InventoryEventsConsumer
elif [ "$APPLICATION_TYPE" = "compliance-sidekiq" ]; then
  exec bundle exec sidekiq
elif [ "$APPLICATION_TYPE" = "compliance-import-remediations" ]; then
  exec bundle exec rake import_remediations --trace
elif [ "$APPLICATION_TYPE" = "compliance-import-ssg" ]; then
  exec bundle exec rake ssg:import_rhel_supported --trace
elif [ "$APPLICATION_TYPE" = "sleep" ]; then
  while true; do sleep 60; done
else
  echo "Application type '$APPLICATION_TYPE' not supported"
fi
