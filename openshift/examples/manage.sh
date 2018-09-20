#!/bin/bash
#
#   Openshift cluster examples
#
#   REMEMBER TO check syntax with https://github.com/koalaman/shellcheck
#

#set -x          # debug enabled
#set -e          # exit on first error
set -o pipefail # exit on any errors in piped commands

#ENVIRONMENT VARIABLES

declare SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare CURRENT_PATH=$( pwd )
declare OS_CMD="oc "


declare PARAM=''

function parseCli(){
  if [[ "$#" -eq 0 ]]; then
    usage
  fi
  while [[ "$#" -gt 0 ]]; do
    key="$1"
    val="$2"
    case $key in
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
  setEnvContext
  declare DOCKER_REGISTRY_ROUTE=$(${OS_CMD} get route docker-registry  -n default -o jsonpath='{.spec.host}')
  declare DOCKER_REGISTRY_IP=$(${OS_CMD} get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
  case $PARAM in
    #
    # --- namespace ---
    #     
    test)
      ${OS_CMD} projects
    ;;
    namespace-config)
      # --- Create account
      ${OS_CMD} new-project ${OPENSHIFT_NAMESPACE}
      ${OS_CMD} project  ${OPENSHIFT_NAMESPACE}
      ${OS_CMD} create sa ${OPENSHIFT_SERVICE_ACCOUNT}
      # ${OS_CMD} policy add-role-to-user system:image-builder  system:serviceaccount:${OPENSHIFT_NAMESPACE}:${OPENSHIFT_SERVICE_ACCOUNT}
      # Need to have permission on processedtemplates.template.openshift.io and to push to registry
      ${OS_CMD} policy add-role-to-user admin -z ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE}
    ;;
    # TODO: check before run....     
    # example-nfs-deploy)
    #   ${K8S_CMD} create -f ${SCRIPT_PATH}/templates/nfs-pv.yml
    #   ${K8S_CMD} create -f ${SCRIPT_PATH}/templates/nfs-pvc.yml
    #   #${K8S_CMD} create -f ${SCRIPT_PATH}/templates/nfs-nginx.yml
    #   ${K8S_CMD} create -f ${SCRIPT_PATH}/templates/nfs-rhel.yml
    # ;;
    # example-nfs-delete)
    #   ${K8S_CMD} delete -f ${SCRIPT_PATH}/templates/nfs-pv.yml
    #   ${K8S_CMD} delete -f ${SCRIPT_PATH}/templates/nfs-pvc.yml
    #   #${K8S_CMD} delete -f ${SCRIPT_PATH}/templates/nfs-nginx.yml
    #   ${K8S_CMD} delete -f ${SCRIPT_PATH}/templates/nfs-rhel.yml
    # ;;      
    #
    # --- python-web-server ---
    #      
    python-web-server-build)
      # --- Build docker
      TOKEN=$(${OS_CMD} sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      IMAGE="${DOCKER_REGISTRY_ROUTE}/${OPENSHIFT_NAMESPACE}/python-web-server:latest"
      docker build -f ${SCRIPT_PATH}/python-web-server/Dockerfile -t ${IMAGE} ${SCRIPT_PATH}/python-web-server
      docker login -u developer -p "${TOKEN}" ${DOCKER_REGISTRY_ROUTE} 
      docker push ${IMAGE}
    ;;
    python-web-server-deploy)  
      # --- Deploy app
      TOKEN=$(${OS_CMD} sa get-token ${OPENSHIFT_SERVICE_ACCOUNT} -n ${OPENSHIFT_NAMESPACE} )
      ${OS_CMD} new-app --token="${TOKEN}" \
      -f ${SCRIPT_PATH}/python-web-server/template.yaml \
      --param=DOCKER_REGISTRY=${DOCKER_REGISTRY_IP}
    ;;
    python-web-server-delete)
      ${OS_CMD} delete all -l rndid=python-web-server -n ${OPENSHIFT_NAMESPACE}
    ;;
    #
    # --- pytorch-operator ---
    #      
    pytorch-operator-install)
      # Poc https://github.com/kubeflow/pytorch-operator
      # Install k8s schema
      #brew install ksonnet/tap/ks
      mkdir -p ${SCRIPT_PATH}/pytorch/ks
      cd ${SCRIPT_PATH}/pytorch/ks
      KS_APP="kubeflow"
      ks init ${KS_APP}
      cd ${SCRIPT_PATH}/pytorch/ks/${KS_APP}
      ks registry add -o -v  kubeflow github.com/kubeflow/kubeflow/tree/v0.2.2/kubeflow
      ks pkg install kubeflow/pytorch-job@master
      ks prototype use io.ksonnet.pkg.pytorch-operator pytorch-operator \
      --namespace default  --name pytorch-operator
      ks prototype use io.ksonnet.pkg.pytorch-job pytorch-job \
        --namespace default --name pytorch-job    

      #As always relax all privileges
      #https://github.com/kubeflow/kubeflow/pull/641
      oc policy add-role-to-user cluster-admin -z pytorch-operator -n default
    ;;
    pytorch-operator-send-receive-deploy)
      OPENSHIFT_NAMESPACE="default"
      TOKEN=$(${OS_CMD} sa get-token pytorch-operator -n ${OPENSHIFT_NAMESPACE} )
      IMAGE="${DOCKER_REGISTRY_ROUTE}/${OPENSHIFT_NAMESPACE}/pytorch-send-receive:latest"
      docker build -f ${SCRIPT_PATH}/pytorch/send-receive/Dockerfile -t ${IMAGE} ${SCRIPT_PATH}/pytorch/send-receive
      docker login -u developer -p "${TOKEN}" ${DOCKER_REGISTRY_ROUTE} 
      docker push ${IMAGE}      
      ${OS_CMD} create -f ${SCRIPT_PATH}/pytorch/send-receive/pytorch_job.yaml
    ;;
    pytorch-operator-send-receive-delete)
      OPENSHIFT_NAMESPACE="default"
      ${OS_CMD} delete all -l pytorch_job_name=pytorch-send-receive -n ${OPENSHIFT_NAMESPACE}
    ;;
    # 
    #
    # --- Minio k8s config generator ---
    #   
    minio-deploy)
      ${OS_CMD} create -f ${SCRIPT_PATH}/minio/minio-web-config.yaml
    ;;
    minio-delete)
      ${OS_CMD} delete -f ${SCRIPT_PATH}/minio/minio-web-config.yaml
    ;;
    #
    # --- rook minio operator ---
    # https://rook.io/ - DID NOT WORK
    #
    # rook-minio-operator-deploy)
    #   ${OS_CMD} create -f ${SCRIPT_PATH}/rook-minio/object-store.yaml
    #   ${OS_CMD} create -n "rook-minio-system" -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/minio/operator.yaml
    #   ${OS_CMD} create -n "rook-minio" -f ${SCRIPT_PATH}/rook-minio/object-store.yaml
    # ;;
    # rook-minio-operator-delete)
    #   ${OS_CMD} delete -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/minio/operator.yaml
    #   ${OS_CMD} delete -f ${SCRIPT_PATH}/rook-minio/object-store.yaml
    # ;;
     
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

# @info:	Set default OS context
function setEnvContext() {
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

# @info:	Check default OS context
# function occontext {
#   if [[ ! -z "${OS_CONTEXT}" ]]; then
#     #echo "!!! Found OS_CONTEXT env: ${OS_CONTEXT} !!!"
#     #oc whoami --context=$OS_CONTEXT || exit 1
#     oc --context=$OS_CONTEXT "$@"
#   else
#     oc "$@"
#   fi
# }


parseCli "$@"

cd ${CURRENT_PATH}






