#!/bin/bash
#
#   systemd service
#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#   Credits http://www.jcgonzalez.com/ubuntu-16-java-service-wrapper-example
#

#set -x          # debug enabled
set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

# ENVIRONMENT VARIABLES
# declare SCRIPT_DIR=''
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

declare SERVICE_NAME="APPS - Bash hello world"
declare PATH_TO_BIN=/opt/applications/bash-hello-world/bash-hello-world.sh
declare PATH_TO_LOG=/opt/applications/bash-hello-world/logs/app.log
declare PID_PATH_NAME=/opt/applications/bash-hello-world/app.pid

# @info:    Parses and validates the CLI arguments
# @args:	Global Arguments $@

function parseCli(){
    if [[ "$#" -eq 0 ]]; then
        usage
    fi
    while [[ "$#" -gt 0 ]]; do
        key="$1"
        #val="$2"
        case $key in
            start) start; exit 0;;
            stop) stop; exit 0;;
            reload) reload; exit 0;;
            -h | --help | *) usage; exit 0 ;;
        esac
        shift
    done
    
}

# @info:	Prints out usage
function usage {
    echo
    echo "  ${0}: "
    echo "-------------------------------"
    echo
    echo "  -h or --help          Opens this help menu"
    echo
    echo "  start                 start service "
    echo "  stop                  stop service "
    echo "  reload                reload service "
    echo
}

function start()  {
    if [ ! -f $PID_PATH_NAME ]; then
        echo "${SERVICE_NAME} starting ..."
        nohup ${PATH_TO_BIN}  >> ${PATH_TO_LOG} 2>&1 &
        echo $! > ${PID_PATH_NAME}
        echo "${SERVICE_NAME} started ..."
    else
        echo "${SERVICE_NAME} is already running ..."
    fi
    
}

function stop()  {
    if [ -f ${PID_PATH_NAME} ]; then
        PID=$(cat ${PID_PATH_NAME});
        echo "${SERVICE_NAME} stopping ..."
        kill "${PID}" || echo "Process with PID ${PID} not found...";
        echo "${SERVICE_NAME} stopped ..."
        rm ${PID_PATH_NAME}
    else
        echo "${SERVICE_NAME} is not running ..."
    fi
}

function reload()  {
    echo " - Reload service ...."
    stop
    sleep 1
    start
}

parseCli "$@"
