#!/usr/bin/env bashio
set +u

WAIT_PIDS=()
ADDON_PATH='/share/frp'
CONFIG_PATH='/share/frp/frps.ini'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
}

function logger() {
    local log_file=$1
    tail -f -F -q -n 0 $log_file | while read output
    do
        bashio::log.info $output
    done
}

bashio::log.info "Starting frp client"

mkdir -p $ADDON_PATH || bashio::exit.nok "Could not create ${ADDON_PATH} folder"

if ! bashio::fs.file_exists $CONFIG_PATH; then
    bashio::fatal "Can't find ${CONFIG_PATH}"
    bashio::exit.nok
fi

log_file=$(sed -n "/^[ \t]*\[common\]/,/\[/s/^[ \t]*log_file[ \t]*=[ \t]*//p" ${CONFIG_PATH})

if [[ ! -n "${log_file}" ]]; then
    bashio::log.info 'Please specify a path to log file in config file'
    bashio::exit.nok
fi

 curl -o /tmp/frp_0.9.3_linux_amd64.tar.gz -sSL https://github.com/fatedier/frp/releases/download/v0.9.3/frp_0.9.3_linux_amd64.tar.gz
 
 tar xzf /tmp/frp_0.9.3_linux_amd64.tar.gz -C /tmp
 
 cp  /tmp/frp_0.9.3_linux_amd64/frpc /usr/src/
 cp  /tmp/frp_0.9.3_linux_amd64/frps /usr/src/   
cd /usr/src
/tmp/frp_0.9.3_linux_amd64/frpc -c $CONFIG_PATH & logger $log_file & WAIT_PIDS+=($!)
/tmp/frp_0.9.3_linux_amd64/frps -c $CONFIG_PATH & logger $log_file & WAIT_PIDS+=($!)
./frpc -c $CONFIG_PATH & logger $log_file & WAIT_PIDS+=($!)
./frps -c $CONFIG_PATH & logger $log_file & WAIT_PIDS+=($!)
trap "stop_frps" SIGTERM SIGHUP

# Wait and hold Add-on running
wait "${WAIT_PIDS[@]}"
