#!/bin/bash
#
#   Openshift cluster helper script
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

# Check platform
declare PLATFORM=$(uname)
if [[ "$PLATFORM" != 'Darwin' ]]; then
  echo " Only Mac Os X is supported"
  exit 1
fi


declare PARAM_OPENSHIFT=''
function parseCli(){
  if [[ "$#" -eq 0 ]]; then
    usage
  fi
  while [[ "$#" -gt 0 ]]; do
    key="$1"
    val="$2"
    case $key in
      #openshift | os) PARAM_OPENSHIFT=$val; openshift; exit 0;;
      -h | --help ) usage; exit 0 ;;
      *) PARAM_OPENSHIFT=$key; openshift; exit 0;;
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
  echo "               acl-for-admin"
  echo "               login-admin"
  echo "               create-user-developer"
  echo "               get-info                                 - Get cluster user, roles and scc info"
  echo "               get-default-templates                    - Get templates in openshift namespace"
  echo "               get-all"
  echo "               diagnostic"
  echo "               import-docker-image-busy-box"
  echo
  echo
  echo
}


#
# --------- Openshift ----------------------------------------------------------
#
declare OPENSHIFT_VAGRANT_MASTER="centos-01"
declare OPENSHIFT_VAGRANT_CLUSTER_URL="https://${OPENSHIFT_VAGRANT_MASTER}:8443"
declare OPENSHIFT_VERSION="3.10.0"

function openshift() {

  case $PARAM_OPENSHIFT in
    #
    # --- Minishift ---
    #  
    minishift-upgrade)
      brew cask upgrade minishift
      brew upgrade kubernetes-cli
      minishift delete
    ;;
    minishift-up)
      minishift addon enable admin-user
      minishift addon enable registry-route
      minishift start --vm-driver virtualbox --memory 8GB ## --routing-suffix TODO 
    ;;
    minishift-login-admin)
      SERVER="https://$( minishift ip ):8443"
      echo " * Login to ${SERVER} with user:admin password:admin "
      ${OS_CMD} login -u admin -p admin --server=${SERVER} --insecure-skip-tls-verify --loglevel 5
    ;;
    minishift-info)
      setEnvContext
      DOCKER_REGISTRY_ROUTE=$(${OS_CMD} get route docker-registry  -n default -o jsonpath='{.spec.host}')
      DOCKER_REGISTRY_IP=$(${OS_CMD} get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
      echo " * Minishift current context: $(${OS_CMD} config current-context)"
      echo " * Minishift ip: $( minishift ip) "
      echo " * Docker registry route: ${DOCKER_REGISTRY_ROUTE}"
      echo " * Docker registry internal pod ip: ${DOCKER_REGISTRY_IP}"
    ;;
    minishift-clock)
      echo "Current date in minishift: $(minishift ssh date)"
      DATE_SEC=$(  date +%s )
      minishift ssh "timedatectl set-timezone Europe/Rome"
      minishift ssh "sudo date -s '@${DATE_SEC}'"
      echo "New date in minishift: $(minishift ssh date)"
    ;;
    #
    # --- Docker ---
    # Only with openshift oc client
    #     
    docker-up)
      command -v docker >/dev/null 2>&1 || {
        echo " * ERROR: install docker and retry!"
        exit 1
      }
      command -v socat >/dev/null 2>&1 || {
        echo " * Install brew socat"
        brew install socat
      }
      echo " * Edit docker insecure registry and add '172.30.0.0/16' "    
      msg "Start up cluster with docker"
      # Sync internal docker clock with guest os
      cmd "docker run -it --rm --privileged --pid=host debian nsenter -t 1 -m -u -n -i date -u $(date -u +%m%d%H%M%Y)"
      cmd "oc cluster up --version=v${OPENSHIFT_VERSION} --http-proxy=docker.for.mac.http.internal:3128 --https-proxy=docker.for.mac.http.internal:3129"
      msg " !! IMPORTANT !! - If router and docker registry are not running: create admin user with this script, login and restart router and docker registry"
    ;;
    docker-down)
      echo "Stop cluster"
      oc cluster down
      oc config delete-cluster 127-0-0-1:8443
    ;;
    docker-login-admin)
      declare OPENSHIFT_DOCKER_CLUSTER_URL="https://127.0.0.1:8443"
      oc login -u system:admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
      oc create user admin
      oc adm policy add-cluster-role-to-user cluster-admin admin
      oc login -u admin -p admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;

    #
    # --- Vagrant ---
    #     
    # make user admin to be a real admin, must be run on a master node
    vagrant-acl-for-admin)
      vagrant ssh ${OPENSHIFT_VAGRANT_MASTER} -c "${OS_CMD} adm policy add-cluster-role-to-user cluster-admin admin"
    ;;
    # User admin password admin created at install time
    vagrant-login-admin)
      ${OS_CMD} login -u admin -p admin --server=${OPENSHIFT_VAGRANT_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;

    #
    # --- Common tasks ---
    # 
    openshift-registry-console-deploy)
      setEnvContext
      OPENSHIFT_HOSTNAME=$(${OS_CMD} config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
      # TODO: fix and update https://docs.openshift.com/container-platform/3.10/install_config/registry/deploy_registry_existing_clusters.html#registry-console
      # TODO: look for registry console 9.10....
      echo "TODO: Still using version 3.9 - Update registry console to version 3.10"
      # OLD 3.9 
      ${OS_CMD} create -n default -f https://raw.githubusercontent.com/openshift/openshift-ansible/release-3.9/roles/openshift_hosted_templates/files/v3.9/origin/registry-console.yaml
      ${OS_CMD} create route passthrough --service registry-console --port registry-console -n default
      ${OS_CMD} new-app -n default --template=registry-console \
          -p OPENSHIFT_OAUTH_PROVIDER_URL="https://${OPENSHIFT_HOSTNAME}:8443" \
          -p REGISTRY_HOST=$(${OS_CMD} get route docker-registry -n default --template='{{ .spec.host }}') \
          -p COCKPIT_KUBE_URL=$(${OS_CMD} get route registry-console -n default --template='https://{{ .spec.host }}')
    ;;

    openshift-registry-console-delete)
      setEnvContext
      ${OS_CMD} delete all -l createdBy=registry-console-template -n default
      ${OS_CMD} delete OAuthClient cockpit-oauth-client
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



    #
    # --- Openshift examples ---
    # 
    # https://github.com/openshift/origin/tree/release-3.10/examples
    #
 
    # From https://github.com/openshift/origin/tree/release-3.10/examples/quickstarts
    example-django-deploy)
      setEnvContext
      echo " * Start node example from git repo (use s2i)"
      ${OS_CMD} new-app -f https://raw.githubusercontent.com/openshift/origin/release-3.10/examples/quickstarts/django-postgresql-persistent.json -l name=django-example
      echo " * Follow build logs"
      ${OS_CMD} logs -f bc/nodejs-ex
      echo " * Expose route to outside"
      ${OS_CMD} expose svc/nodejs-ex
    ;;
    example-django-delete)
      setEnvContext
      # use label selector to delete
      echo " * Delete all objects"
      ${OS_CMD} delete all -l name=django-example
    ;;

    # From https://github.com/openshift/origin/blob/release-3.10/examples/quickstarts/nginx.json
    example-nginx-deploy)
      setEnvContext
      echo " * Start node example from git repo (use s2i)"
      ${OS_CMD} new-app -f https://raw.githubusercontent.com/openshift/origin/release-3.10/examples/quickstarts/nginx.json -l name=nginx-example
      echo " * Follow build logs"
      ${OS_CMD} logs -f bc/nginx-example
      echo " * Expose route to outside"
      ${OS_CMD} expose svc/nodejs-ex
    ;;
    example-nginx-delete)
      setEnvContext
      # use label selector to delete
      echo " * Delete all objects"
      ${OS_CMD} delete all -l name=nginx-example
    ;;

    example-deploy-local-storage)
      setEnvContext
      echo " * Build and deploy local storage template -> https://github.com/openshift/origin/tree/release-3.10/examples/storage-examples/host-path-examples"
      echo "TO DO ...."
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




    # #
    # # --- Custom examples ---
    # #

    # example-deploy-scala-hello-world)
    #   ${OS_CMD} login -u developer
    #   echo " * Delete scala-hello-world"
    #   #${OS_CMD} delete
    #   ${OS_CMD} delete template 'sbt-jenkins-pipeline'
    #   ${OS_CMD} delete imagestreams "wildfly"
    #   ${OS_CMD} delete buildconfigs "scala-hello-world-docker"
    #   ${OS_CMD} delete imagestreams,buildconfigs,deploymentconfigs,services,routes "scala-hello-world"

    #   echo " * Build scala-hello-world"
    #   ${OS_CMD} create -f ${SCRIPT_PATH}/../boilerplates/scala-hello-world/openshift/sbt-jenkins-pipeline.yaml
    #   ${OS_CMD} new-app sbt-jenkins-pipeline # build, export artifact to anothe image, and deploy
    #   ${OS_CMD} start-build scala-hello-world
    #   openshiftWebConsole

    # ;;

# function openshiftInstallDocker() {
#   # Prerequisites
#   command -v docker >/dev/null 2>&1 || {
#     echo " * ERROR: install docker and retry!"
#     exit 1
#   }
#   command -v socat >/dev/null 2>&1 || {
#     echo " * Install brew socat"
#     brew install socat
#   }
#   echo " * Edit docker insecure registry and add '172.30.0.0/16' "
# }