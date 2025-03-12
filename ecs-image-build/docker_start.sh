#!/bin/bash
#
# Start script for ch.gov.uk running in ecs

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PORT=${PORT:=10000}

export PERL5LIB="${APP_DIR}/local/lib/perl5"
exec perlbrew exec perl "${APP_DIR}/script/start_app" daemon -l "http://*:${PORT}"