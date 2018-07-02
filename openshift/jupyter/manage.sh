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
declare OPENSHIFT_REGISTRY=$(oc get route docker-registry  -n default -o jsonpath='{.spec.host}')
declare DOCKER_REGISTRY=$(oc get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')

function parse() {
  case $PARAM in
    build)
      # --- Create account
      oc new-project ${OPENSHIFT_NAMESPACE}
      oc project  ${OPENSHIFT_NAMESPACE}
      oc create sa ${OPENSHIFT_SERVICE_ACCOUNT}
      oc policy add-role-to-user system:image-builder  system:serviceaccount:${OPENSHIFT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}
      TOKEN=$(oc sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      # --- Build docker
      IMAGE="${OPENSHIFT_REGISTRY}/${OPENSHIFT_NAMESPACE}/${OPENSHIFT_APP}:latest"
      docker build -f ${SCRIPT_PATH}/Dockerfile -t ${IMAGE} ${SCRIPT_PATH}
      docker login -u developer -p "${TOKEN}" ${OPENSHIFT_REGISTRY} 
      docker push ${IMAGE}
    ;;
    deploy)  
      # --- Deploy app
      # Need to have permission on processedtemplates.template.openshift.io
      oc policy add-role-to-user admin -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
      # Need to access nvidia socket
      oc adm policy add-scc-to-user privileged -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
      TOKEN=$(oc sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      oc new-app --token="${TOKEN}" \
      -f ${SCRIPT_PATH}/os-template.yaml \
      --param=APP_NAME=${OPENSHIFT_APP}  \
      --param=DOCKER_REGISTRY=${DOCKER_REGISTRY}  \
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






