#!/bin/bash
#
#   Example bash script
#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#

#set -x          # debug enabled
set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

declare SCRIPT_DIR; SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# @info:  Parses and validates the CLI arguments
# @args:	Global Arguments $@

function parseCli() {
  while [[ "$#" -gt 0 ]]; do
    declare KEY="$1"
    declare VALUE="$2"
    case "${KEY}" in
    # exec command here
    #
    # --- Minishift ---
    #
    upgrade)
      brew update
      brew cask install minishift || (brew cask upgrade minishift && brew cask cleanup minishift)
      brew install openshift-cli || (brew upgrade openshift-cli && brew cleanup openshift-cli)
      brew install kubernetes-cli || (brew upgrade kubernetes-cli && brew cleanup kubernetes-cli)
      exit 0
    ;;
    up)
      minishift addon enable admin-user
      minishift addon enable registry-route
      minishift start --vm-driver virtualbox --memory 8GB ## --routing-suffix TODO 
      exit 0
    ;;
    login-admin)
      SERVER="https://$( minishift ip ):8443"
      echo " * Login to ${SERVER} with user:admin password:admin "
      oc login -u admin -p admin --server="${SERVER}" --insecure-skip-tls-verify --loglevel 5
      exit 0
    ;;
    docker-login-admin)
      docker login -u admin -p "$(oc whoami -t)" "$(minishift openshift registry)"
      exit 0
    ;;
    info)
      DOCKER_REGISTRY_ROUTE=$(oc get route docker-registry  -n default -o jsonpath='{.spec.host}')
      DOCKER_REGISTRY_IP=$(oc get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
      echo " * Minishift current context: $(oc config current-context)"
      echo " * Minishift ip: $( minishift ip) "
      echo " * Docker registry route: ${DOCKER_REGISTRY_ROUTE}"
      echo " * Docker registry internal pod ip: ${DOCKER_REGISTRY_IP}"
      exit 0
    ;;
    set-clock)
      echo "Current date in minishift: $(minishift ssh date)"
      DATE_SEC=$(  date +%s )
      minishift ssh "timedatectl set-timezone Europe/Rome"
      minishift ssh "sudo date -s '@${DATE_SEC}'"
      echo "New date in minishift: $(minishift ssh date)"
      exit 0
    ;;
    -action)
      echo "Key: ${KEY} - Value: ${VALUE}"
      echo "Script dir is: ${SCRIPT_DIR}"
      exit 0
      ;;
    -h | *)
      echo "  ${0}: "
      echo ""
      echo "               -action value               first param "
      exit 0
      ;;
    esac
    shift
  done
  ${0} -h
}

parseCli "$@"

    #
    # --- Docker ---
    # Only with openshift oc client
    #     
    # docker-up)
    #   command -v docker >/dev/null 2>&1 || {
    #     echo " * ERROR: install docker and retry!"
    #     exit 1
    #   }
    #   command -v socat >/dev/null 2>&1 || {
    #     echo " * Install brew socat"
    #     brew install socat
    #   }
    #   echo " * Edit docker insecure registry and add '172.30.0.0/16' "    
    #   msg "Start up cluster with docker"
    #   # Sync internal docker clock with guest os
    #   cmd "docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)"
    #   cmd "oc cluster up --version=v${OPENSHIFT_VERSION} --http-proxy=docker.for.mac.http.internal:3128 --https-proxy=docker.for.mac.http.internal:3129"
    #   msg " !! IMPORTANT !! - If router and docker registry are not running: create admin user with this script, login and restart router and docker registry"
    # ;;
    # docker-down)
    #   echo "Stop cluster"
    #   oc cluster down
    #   oc config delete-cluster 127-0-0-1:8443
    # ;;
    # docker-login-admin)
    #   declare OPENSHIFT_DOCKER_CLUSTER_URL="https://127.0.0.1:8443"
    #   oc login -u system:admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    #   oc create user admin
    #   oc adm policy add-cluster-role-to-user cluster-admin admin
    #   oc login -u admin -p admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    # ;;