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
declare OPENSHIFT_NAMESPACE="jupyter"
declare OPENSHIFT_SERVICE_ACCOUNT="jupyter"
declare OPENSHIFT_APP="jupyter"

function parse() {
  declare OPENSHIFT_HOSTNAME=$(occontext config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
  declare OPENSHIFT_REGISTRY=$(occontext get route docker-registry  -n default -o jsonpath='{.spec.host}')
  declare DOCKER_REGISTRY=$(occontext get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
  case $PARAM in
    test)
      A=$(occontext projects)
      echo $A
    
    ;;
    simple-config)
      # --- Create account
      occontext new-project ${OPENSHIFT_NAMESPACE}
      occontext project  ${OPENSHIFT_NAMESPACE}
      occontext create sa ${OPENSHIFT_SERVICE_ACCOUNT}
      # occontext policy add-role-to-user system:image-builder  system:serviceaccount:${OPENSHIFT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}
      # Need to have permission on processedtemplates.template.openshift.io
      occontext policy add-role-to-user admin -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
      # Need to access nvidia socket
      occontext adm policy add-scc-to-user privileged -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
    ;;
    simple-build)
      # --- Build docker
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      IMAGE="${OPENSHIFT_REGISTRY}/${OPENSHIFT_NAMESPACE}/${OPENSHIFT_APP}:latest"
      docker build -f ${SCRIPT_PATH}/Dockerfile -t ${IMAGE} ${SCRIPT_PATH}
      docker login -u developer -p "${TOKEN}" ${OPENSHIFT_REGISTRY} 
      docker push ${IMAGE}
    ;;
    simple-deploy)  
      # --- Deploy app
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      occontext new-app --token="${TOKEN}" \
      -f ${SCRIPT_PATH}/os-template.yaml \
      --param=APP_NAME=${OPENSHIFT_APP}  \
      --param=DOCKER_REGISTRY=${DOCKER_REGISTRY}  \
      -l rndid=${OPENSHIFT_APP}
    ;;
    simple-delete)
      occontext delete all -l rndid=${OPENSHIFT_APP} -n ${OPENSHIFT_NAMESPACE}
    ;;
    hub-config)
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      occontext create --token="${TOKEN}" -f https://raw.githubusercontent.com/jupyter-on-openshift/jupyter-notebooks/master/images.json -n ${OPENSHIFT_NAMESPACE}
      occontext logs --token="${TOKEN}" --follow bc/s2i-minimal-notebook
      occontext create --token="${TOKEN}" -f https://raw.githubusercontent.com/jupyter-on-openshift/jupyterhub-quickstart/master/images.json -n ${OPENSHIFT_NAMESPACE}
      occontext logs --token="${TOKEN}" --follow bc/jupyterhub
      occontext create --token="${TOKEN}" -f https://raw.githubusercontent.com/jupyter-on-openshift/jupyterhub-quickstart/master/templates.json
    ;;
    hub-deploy)
      # https://github.com/jupyter-on-openshift/jupyterhub-quickstart#customising-the-jupyterhub-deployment
      TOKEN=$(occontext sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      occontext new-app --template jupyterhub-deployer --token="${TOKEN}"
    ;;
    hub-delete)
      occontext delete all,configmap,pvc,serviceaccount,rolebinding --selector app=jupyterhub -n ${OPENSHIFT_NAMESPACE}
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






