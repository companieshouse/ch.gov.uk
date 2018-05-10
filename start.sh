#!/bin/bash
#
# Start script for ch.gov.uk

APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z "${MESOS_SLAVE_PID}" ]]; then
    source ~/.chs_env/private_env
    source ~/.chs_env/global_env
    source ~/.chs_env/ch.gov.uk/env

    PORT="${CHS_CH_PORT:=3000}"
else
    PORT="$1"
    CONFIG_URL="$2"
    ENVIRONMENT="$3"
    APP_NAME="$4"

    source /etc/profile

    echo "Downloading environment from: ${CONFIG_URL}/${ENVIRONMENT}/${APP_NAME}"
    wget -O "${APP_DIR}/private_env" "${CONFIG_URL}/${ENVIRONMENT}/private_env"
    wget -O "${APP_DIR}/global_env" "${CONFIG_URL}/${ENVIRONMENT}/global_env"
    wget -O "${APP_DIR}/app_env" "${CONFIG_URL}/${ENVIRONMENT}/${APP_NAME}/env"
    source "${APP_DIR}/private_env"
    source "${APP_DIR}/global_env"
    source "${APP_DIR}/app_env"

    echo "Setting up log4perl.conf"
    mv "${APP_DIR}/log4perl.production.conf" "${APP_DIR}/log4perl.conf"
    sed -i "s|<FLUENTD_TAG_PREFIX>|${APP_NAME}|g" "${APP_DIR}/log4perl.conf"

    export PATH
    export PATH="/opt/plenv/bin:${PATH}"
    export PLENV_ROOT=/opt/plenv

    eval "$(plenv init -)"

    export MOJO_MODE=production
    APP_ARGS="--proxy"
fi

export PERL5LIB="${APP_DIR}/local/lib/perl5"
exec plenv exec perl "${APP_DIR}/script/start_app" daemon -l "http://*:${PORT}" "${APP_ARGS}"
