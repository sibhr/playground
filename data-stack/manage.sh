#!/bin/bash
#

#set -x          # debug enabled
set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

declare SCRIPT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# @info:  Parses and validates the CLI arguments
# @args:	Global Arguments $@

function parseCli() {
  while [[ "$#" -gt 0 ]]; do
    declare KEY="$1"
    declare VALUE="$2"
    case "${KEY}" in
    # exec command here
    superset-clone)
      git clone https://github.com/apache/incubator-superset.git superset/incubator-superset
      exit 0
      ;;
    superset-run-compose)
      cd "${SCRIPT_DIR}/superset/incubator-superset/contrib/docker"
      # prefix with SUPERSET_LOAD_EXAMPLES=yes to load examples:
      export SUPERSET_LOAD_EXAMPLES=yes
      docker-compose run --rm superset ./docker-init.sh
      docker-compose up
      cd "${SCRIPT_DIR}"
      exit 0
      ;;
    -h | *)
      echo "  ${0}: "
      echo ""
      echo "               superset-clone        --- clone https://github.com/apache/incubator-superset.git"
      echo "               superset-run-compose  --- build and run docker compose"
      exit 0
      ;;
    esac
    shift
  done
  ${0} -h
}

parseCli "$@"
