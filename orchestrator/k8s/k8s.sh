#!/bin/bash
#
#   K8s cluster helper script
#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#

#set -x          # debug enabled
#set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

declare SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare CURRENT_PATH=$( pwd )
declare OS_CMD="kubectl "

# Check platform
declare PLATFORM=$(uname)
if [[ "$PLATFORM" != 'Darwin' ]]; then
  echo " Only Mac Os X is supported"
  exit 1
fi


declare PARAM_CLI=''
function parseCli(){
  if [[ "$#" -eq 0 ]]; then
    usage
  fi
  while [[ "$#" -gt 0 ]]; do
    key="$1"
    val="$2"
    case $key in
      -h | --help ) usage; exit 0 ;;
      *) PARAM_CLI=$key; k8s_cli; exit 0;;
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
  echo "  minikube-upgrade"
  echo "  minikube-up"
  echo
}


#
# --------- K8s ----------------------------------------------------------
#

function k8s_cli() {

  case $PARAM_CLI in
    #
    # --- minikube ---
    #  
    minikube-upgrade)
      brew cask install minikube
      brew upgrade kubernetes-cli
      minikube delete
    ;;
    minikube-up)
      minikube start --vm-driver virtualbox --memory 8192
    ;;
    minikube-login-admin)
      SERVER="https://$( minikube ip ):8443"
      echo " * Login to ${SERVER} with user:admin password:admin "
      ${OS_CMD} login -u admin -p admin --server=${SERVER} --insecure-skip-tls-verify --loglevel 5
    ;;
    minikube-info)
      setEnvContext
      DOCKER_REGISTRY_ROUTE=$(${OS_CMD} get route docker-registry  -n default -o jsonpath='{.spec.host}')
      DOCKER_REGISTRY_IP=$(${OS_CMD} get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
      echo " * minikube current context: $(${OS_CMD} config current-context)"
      echo " * minikube ip: $( minikube ip) "
      echo " * Docker registry route: ${DOCKER_REGISTRY_ROUTE}"
      echo " * Docker registry internal pod ip: ${DOCKER_REGISTRY_IP}"
    ;;


    #
    # --- Common tasks ---
    # 

    create-user-developer)
      setEnvContext
      ${OS_CMD} create user developer
      ${OS_CMD} login --username=developer --password=developer
    ;;

    get-auth)
      setEnvContext
      msg " * Get cluster user, roles and scc info"
      cmd "${OS_CMD} get scc"
      cmd "${OS_CMD} get roleBindings"
      cmd "${OS_CMD} get policyBindings"
      cmd "${OS_CMD} get clusterPolicyBindings"
      cmd "${OS_CMD} get user"
      echo " To have more details run same commands with ${OS_CMD} describe [scc | ...]"
    ;;

    get-all)
      setEnvContext
      msg "Get templates"
      cmd "${OS_CMD} get templates --show-labels=true --all-namespaces=true"
      msg "Get persistent volumes"
      cmd "${OS_CMD} get pv  --show-labels=true --all-namespaces=true"
      msg "Get persistent volume claims"
      cmd "${OS_CMD} get pvc --show-labels=true --all-namespaces=true"
      msg "Get service accounts"
      cmd "${OS_CMD} get serviceaccounts --show-labels=true --all-namespaces=true"
      msg "Get all objects"
      cmd "${OS_CMD} get all --show-labels=true --all-namespaces=true"
    ;;

    diagnostic)
      setEnvContext
      ${OS_CMD} adm  diagnostics  all
    ;;

    # Only for openshift oc cli
    import-docker-image-busy-box)
      setEnvContext
      ${OS_CMD} import-image default/busysbox:latest --from=docker.io/library/busybox:latest --confirm
    ;;



    *) usage; exit 0 ;;
  esac

}

function setEnvContext(){
  if [[ ! -z "${OS_CONTEXT}" ]]; then
    echo "!!! Found OS_CONTEXT env: ${OS_CONTEXT} !!!"
    USER=$(${OS_CMD} whoami)
    USER_FROM_CONTEXT=$( echo ${OS_CONTEXT}  | cut -d/ -f3 )
    if [[ "${USER}" != "${USER_FROM_CONTEXT}" ]]; then
      echo "ERROR: User from OS_CONTEXT env is: ${USER_FROM_CONTEXT} but it is not authenticated! Try to login..."
      exit 11
    fi
    echo "!!! Logged in user is: ${USER}"
    OS_CMD="${OS_CMD} --context=$OS_CONTEXT "
  fi
}


function msg(){
  echo ""
  echo "-----------------------------------------------------------------------"
  echo "${1}"
  echo "-----------------------------------------------------------------------"
}

function cmd(){
  echo ""
  echo " * Running: '${1}'"
  echo ""
  ${1}
  echo ""
}

parseCli "$@"

cd ${CURRENT_PATH}


