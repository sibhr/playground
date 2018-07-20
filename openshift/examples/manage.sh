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

#
# --------- Openshift ----------------------------------------------------------
#
declare OPENSHIFT_NAMESPACE="examples"
declare OPENSHIFT_SERVICE_ACCOUNT="examples"
declare OPENSHIFT_APP="examples"

function parse() {
  declare OPENSHIFT_HOSTNAME=$(occontext config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
  declare DOCKER_REGISTRY_ROUTE=$(occontext get route docker-registry  -n default -o jsonpath='{.spec.host}')
  declare DOCKER_REGISTRY_IP=$(occontext get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
  case $PARAM in
    test)
      A=$(occontext projects)
      echo $A
    
    ;;
    namespace-config)
      # --- Create account
      occontext new-project ${OPENSHIFT_NAMESPACE}
      occontext project  ${OPENSHIFT_NAMESPACE}
      occontext create sa ${OPENSHIFT_SERVICE_ACCOUNT}
      # occontext policy add-role-to-user system:image-builder  system:serviceaccount:${OPENSHIFT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}
      # Need to have permission on processedtemplates.template.openshift.io and to push to registry
      occontext policy add-role-to-user admin -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
    ;;
    python-web-server-build)
      # --- Build docker
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      IMAGE="${DOCKER_REGISTRY_ROUTE}/${OPENSHIFT_NAMESPACE}/python-web-server:latest"
      docker build -f ${SCRIPT_PATH}/python-web-server/Dockerfile -t ${IMAGE} ${SCRIPT_PATH}/python-web-server
      docker login -u developer -p "${TOKEN}" ${DOCKER_REGISTRY_ROUTE} 
      docker push ${IMAGE}
    ;;
    python-web-server-deploy)  
      # --- Deploy app
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      occontext new-app --token="${TOKEN}" \
      -f ${SCRIPT_PATH}/python-web-server/template.yaml \
      --param=DOCKER_REGISTRY=${DOCKER_REGISTRY_IP}
    ;;
    python-web-server-delete)
      occontext delete all -l rndid=python-web-server -n ${OPENSHIFT_NAMESPACE}
    ;;
    pytorch-operator)
      # Poc https://github.com/kubeflow/pytorch-operator
      # Install k8s schema
      #brew install ksonnet/tap/ks
      mkdir -p ${SCRIPT_PATH}/pytorch/ks
      cd ${SCRIPT_PATH}/pytorch/ks
      KS_APP="kubeflow"
      ks init ${KS_APP}
    ;;


    *) usage; exit 0 ;;
  esac

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

# @info:	Check default OS context
function occontext {
  if [[ ! -z "${OS_CONTEXT}" ]]; then
    #echo "!!! Found OS_CONTEXT env: ${OS_CONTEXT} !!!"
    #oc whoami --context=$OS_CONTEXT || exit 1
    oc --context=$OS_CONTEXT "$@"
  else
    oc "$@"
  fi
}


parseCli "$@"

cd ${CURRENT_PATH}






