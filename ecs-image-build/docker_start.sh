#!/bin/bash
#
# Start script for ch.gov.uk running in ecs

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PORT=${PORT:=10000}

source /opt/perlbrew/etc/bashrc
exec perlbrew exec env PERL5LIB="${APP_DIR}/local/lib/perl5" "${APP_DIR}/script/start_app" daemon -l "http://*:${PORT}"
