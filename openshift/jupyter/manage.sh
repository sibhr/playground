#!/bin/bash
#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#

#set -x          # debug enabled
#set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

# @info:	current version
declare VERSION="1.0.0"
declare SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare CURRENT_PATH=$( pwd )

# @info:    Parses and validates the CLI arguments
# @args:	Global Arguments $@


declare PARAM=''

function parseCli(){
  if [[ "$#" -eq 0 ]]; then
    usage
  fi
  while [[ "$#" -gt 0 ]]; do
    key="$1"
    val="$2"
    case $key in
      -v | --version) version; exit 0 ;;
      -h | --help ) usage; exit 0 ;;
      *) PARAM=$key; parse; exit 0;;
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
  echo " See source code for a list of commands"
  echo
}

#
# --------- Openshift ----------------------------------------------------------
#
declare OPENSHIFT_HOSTNAME=$(oc config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
declare OPENSHIFT_NAMESPACE="jupyter"
declare OPENSHIFT_SERVICE_ACCOUNT="jupyter"
declare OPENSHIFT_APP="jupyter"
declare OPENSHIFT_REGISTRY=$(minishift openshift registry)

function parse() {
  case $PARAM in
    build)
      #minishift addons apply  registry-route
      docker build -f ${SCRIPT_PATH}/Dockerfile -t openshift/jupyter ${SCRIPT_PATH}
      docker tag openshift/jupyter:latest ${OPENSHIFT_REGISTRY}/openshift/jupyter:latest
      docker login -u admin -p $(oc whoami -t) ${OPENSHIFT_REGISTRY}
      docker push ${OPENSHIFT_REGISTRY}/openshift/jupyter:latest
    ;;
    deploy)
      oc new-project ${OPENSHIFT_NAMESPACE}
      oc project  ${OPENSHIFT_NAMESPACE}
      oc create sa ${OPENSHIFT_SERVICE_ACCOUNT}
      #oc policy add-role-to-user admin system:serviceaccounts:${OPENSHIFT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}
      oc policy add-role-to-user admin -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
      TOKEN=$(oc sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      TOKEN=$(oc whoami -t)
      oc new-app --token="${TOKEN}" -f ${SCRIPT_PATH}/os-template.yaml \
      --param=APP_NAME=${OPENSHIFT_APP}  \
      --param=APP_HOSTNAME=${OPENSHIFT_APP}.${OPENSHIFT_HOSTNAME}.nip.io \
      --param=SERVICE_ACCOUNT=${OPENSHIFT_SERVICE_ACCOUNT}  \
      -l rndid=${OPENSHIFT_APP}
    ;;
    delete)
      oc delete all -l rndid=jupyter -n ${OPENSHIFT_NAMESPACE}
    ;;

    *) usage; exit 0 ;;
  esac

}


parseCli "$@"

cd ${CURRENT_PATH}






