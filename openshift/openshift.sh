#!/bin/bash
#
#   Example bash script
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

# @info:  Parses and validates the CLI arguments
# @args:	Global Arguments $@

# Check platform
declare PLATFORM=$(uname)
if [[ "$PLATFORM" != 'Darwin' ]]; then
  echo " Only Mac Os X is supported"
  exit 1
fi

# Set context from env variable
declare K8S_CMD="oc "
if [[ ! -z "${K8S_CONTEXT}" ]]; then
  echo "!!! Found K8S_CONTEXT env: ${K8S_CONTEXT} !!!"
  USER=$(${K8S_CMD} whoami --context=aa$K8S_CONTEXT || kill $$)
  echo "!!! Logged in user is: ${USER}"
  K8S_CMD="${K8S_CMD} --context=$K8S_CONTEXT "
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
      -v | --version) version; exit 0 ;;
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
declare OPENSHIFT_DOCKER_CLUSTER_URL="https://127.0.0.1:8443"
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
      ${K8S_CMD} login -u admin -p admin --server=${SERVER} --insecure-skip-tls-verify --loglevel 5
    ;;
    minishift-info)
      k8sParseContext
      echo " * Minishift context: $(${K8S_CMD} config current-context)"
      echo " * Minishift ip: $( minishift ip) "
      echo " * Docker registry route: ${DOCKER_REGISTRY_ROUTE}"
      echo " * Docker registry internal pod ip: ${DOCKER_REGISTRY_IP}"
    ;;

    #
    # --- Docker ---
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
      cmd "${K8S_CMD} cluster up --version=v${OPENSHIFT_VERSION} --http-proxy=docker.for.mac.http.internal:3128 --https-proxy=docker.for.mac.http.internal:3129"
      msg " !! IMPORTANT !! - If router and docker registry are not running: create admin user with this script, login and restart router and docker registry"
    ;;
    docker-down)
      echo "Stop cluster"
      #${K8S_CMD} login -u system:admin
      #${K8S_CMD} config set-cluster 127-0-0-1:8443
      ${K8S_CMD} cluster down
      ${K8S_CMD} config delete-cluster 127-0-0-1:8443
    ;;
    docker-login-admin)
      ${K8S_CMD} login -u system:admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
      ${K8S_CMD} create user admin
      ${K8S_CMD} adm policy add-cluster-role-to-user cluster-admin admin
      ${K8S_CMD} login -u admin -p admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;

    #
    # --- Vagrant ---
    #     
    # make user admin to be a real admin, must be run on a master node
    vagrant-acl-for-admin)
      vagrant ssh ${OPENSHIFT_VAGRANT_MASTER} -c "${K8S_CMD} adm policy add-cluster-role-to-user cluster-admin admin"
    ;;
    # User admin password admin created at install time
    vagrant-login-admin)
      ${K8S_CMD} login -u admin -p admin --server=${OPENSHIFT_VAGRANT_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;

    #
    # --- Common tasks ---
    # 
    registry-console-deploy)
      k8sParseContext
      echo ${OPENSHIFT_HOSTNAME}
      # TODO: fix and update https://docs.openshift.com/container-platform/3.10/install_config/registry/deploy_registry_existing_clusters.html#registry-console
      # TODO: look for registry console 9.10....
      echo "TODO: Still using version 3.9 - Update registry console to version 3.10"
      # OLD 3.9 
      ${K8S_CMD} create -n default -f https://raw.githubusercontent.com/openshift/openshift-ansible/release-3.9/roles/openshift_hosted_templates/files/v3.9/origin/registry-console.yaml
      ${K8S_CMD} create route passthrough --service registry-console --port registry-console -n default
      ${K8S_CMD} new-app -n default --template=registry-console \
          -p OPENSHIFT_OAUTH_PROVIDER_URL="https://${OPENSHIFT_HOSTNAME}:8443" \
          -p REGISTRY_HOST=$(${K8S_CMD} get route docker-registry -n default --template='{{ .spec.host }}') \
          -p COCKPIT_KUBE_URL=$(${K8S_CMD} get route registry-console -n default --template='https://{{ .spec.host }}')
    ;;

    registry-console-delete)
      ${K8S_CMD} delete all -l createdBy=registry-console-template -n default
      ${K8S_CMD} delete OAuthClient cockpit-oauth-client
    ;;
    #
    # --- Common tasks ---
    # 

    create-user-developer)
      ${K8S_CMD} create user developer
      ${K8S_CMD} login --username=developer --password=developer
    ;;

    get-auth)
      msg " * Get cluster user, roles and scc info"
      cmd "${K8S_CMD} get scc"
      cmd "${K8S_CMD} get roleBindings"
      cmd "${K8S_CMD} get policyBindings"
      cmd "${K8S_CMD} get clusterPolicyBindings"
      cmd "${K8S_CMD} get user"
      echo " To have more details run same commands with ${K8S_CMD} describe [scc | ...]"
    ;;

    get-all)
      msg "Get templates"
      cmd "${K8S_CMD} get templates --show-labels=true --all-namespaces=true"
      msg "Get persistent volumes"
      cmd "${K8S_CMD} get pv  --show-labels=true --all-namespaces=true"
      msg "Get persistent volume claims"
      cmd "${K8S_CMD} get pvc --show-labels=true --all-namespaces=true"
      msg "Get service accounts"
      cmd "${K8S_CMD} get serviceaccounts --show-labels=true --all-namespaces=true"
      msg "Get all objects"
      cmd "${K8S_CMD} get all --show-labels=true --all-namespaces=true"
    ;;

    diagnostic)
      ${K8S_CMD} adm  diagnostics --cluster-context=${K8S_CONTEXT} all
    ;;

    import-docker-image-busy-box)
      ${K8S_CMD} import-image default/busysbox:latest --from=docker.io/library/busybox:latest --confirm
    ;;



    #
    # --- Openshift examples ---
    # 
    # https://github.com/openshift/origin/tree/release-3.10/examples
    #
 
    # From https://github.com/openshift/origin/tree/release-3.10/examples/quickstarts
    example-django-deploy)
      echo " * Start node example from git repo (use s2i)"
      ${K8S_CMD} new-app -f https://raw.githubusercontent.com/openshift/origin/release-3.10/examples/quickstarts/django-postgresql-persistent.json -l name=django-example
      echo " * Follow build logs"
      ${K8S_CMD} logs -f bc/nodejs-ex
      echo " * Expose route to outside"
      ${K8S_CMD} expose svc/nodejs-ex
    ;;
    example-django-delete)
      # use label selector to delete
      echo " * Delete all objects"
      ${K8S_CMD} delete all -l name=django-example
    ;;

    # From https://github.com/openshift/origin/blob/release-3.10/examples/quickstarts/nginx.json
    example-nginx-deploy)
      echo " * Start node example from git repo (use s2i)"
      ${K8S_CMD} new-app -f https://raw.githubusercontent.com/openshift/origin/release-3.10/examples/quickstarts/nginx.json -l name=nginx-example
      echo " * Follow build logs"
      ${K8S_CMD} logs -f bc/nginx-example
      echo " * Expose route to outside"
      ${K8S_CMD} expose svc/nodejs-ex
    ;;
    example-nginx-delete)
      # use label selector to delete
      echo " * Delete all objects"
      ${K8S_CMD} delete all -l name=nginx-example
    ;;

    example-deploy-local-storage)
      echo " * Build and deploy local storage template -> https://github.com/openshift/origin/tree/release-3.10/examples/storage-examples/host-path-examples"
      echo "TO DO ...."
    ;;

    *) usage; exit 0 ;;
  esac

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

function k8sParseContext(){
  OPENSHIFT_HOSTNAME=$(${K8S_CMD} config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
  DOCKER_REGISTRY_ROUTE=$(${K8S_CMD} get route docker-registry  -n default -o jsonpath='{.spec.host}')
  DOCKER_REGISTRY_IP=$(${K8S_CMD} get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
}

parseCli "$@"

cd ${CURRENT_PATH}




    # #
    # # --- Custom examples ---
    # #

    # example-deploy-scala-hello-world)
    #   ${K8S_CMD} login -u developer
    #   echo " * Delete scala-hello-world"
    #   #${K8S_CMD} delete
    #   ${K8S_CMD} delete template 'sbt-jenkins-pipeline'
    #   ${K8S_CMD} delete imagestreams "wildfly"
    #   ${K8S_CMD} delete buildconfigs "scala-hello-world-docker"
    #   ${K8S_CMD} delete imagestreams,buildconfigs,deploymentconfigs,services,routes "scala-hello-world"

    #   echo " * Build scala-hello-world"
    #   ${K8S_CMD} create -f ${SCRIPT_PATH}/../boilerplates/scala-hello-world/openshift/sbt-jenkins-pipeline.yaml
    #   ${K8S_CMD} new-app sbt-jenkins-pipeline # build, export artifact to anothe image, and deploy
    #   ${K8S_CMD} start-build scala-hello-world
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