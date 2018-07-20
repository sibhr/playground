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

# @info:    Parses and validates the CLI arguments
# @args:	Global Arguments $@

# Check platform

declare PLATFORM=$(uname)
if [[ "$PLATFORM" != 'Darwin' ]]; then
  echo " Only Mac os X is supported"
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
  echo "  -v or --version       Prints the current docker-clean version"
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
  echo "               example-scala-hello-world                - Build a scala app with custom jenkins slave"
  echo "               example-local-storage-build"
  echo "               example-nodejs-s2i-build"
  echo "               example-nodejs-s2i-destroy"
  echo
  echo
}



function version() {
  echo "Version: ${VERSION}"
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
#
# --------- Openshift ----------------------------------------------------------
#
declare OPENSHIFT_VAGRANT_MASTER="centos-01"
declare OPENSHIFT_VAGRANT_CLUSTER_URL="https://${OPENSHIFT_VAGRANT_MASTER}:8443"
declare OPENSHIFT_DOCKER_CLUSTER_URL="https://127.0.0.1:8443"


# Set last version to solve issue https://github.com/openshift/origin/pull/13204
declare OPENSHIFT_CLUSTER_DOCKER_VERSION="v3.9.0"

function openshift() {
  declare OPENSHIFT_HOSTNAME=$(occontext config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
  declare DOCKER_REGISTRY_ROUTE=$(occontext get route docker-registry  -n default -o jsonpath='{.spec.host}')
  declare DOCKER_REGISTRY_IP=$(occontext get svc docker-registry  -n default -o jsonpath='{.spec.clusterIP}')
  case $PARAM_OPENSHIFT in
    minishift-up)
      brew cask upgrade minishift
      minishift addon enable admin-user
      minishift addon enable registry-route
      minishift start --vm-driver virtualbox --memory 4GB ## --routing-suffix TODO
    ;;
    minishift-login-admin)
      SERVER="https://$( minishift ip ):8443"
      echo " * Login to ${SERVER} with user:admin password:admin "
      oc login -u admin -p admin --server=${SERVER} --insecure-skip-tls-verify --loglevel 5
    ;;
    minishift-info)
      echo " * Minishift context: $(oc config current-context)"
      echo " * Minishift ip: $( minishift ip) "
      echo " * Docker registry route: ${DOCKER_REGISTRY_ROUTE}"
      echo " * Docker registry internal pod ip: ${DOCKER_REGISTRY_IP}"
    ;;
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
      cmd "oc cluster up --version=${OPENSHIFT_CLUSTER_DOCKER_VERSION} --http-proxy=docker.for.mac.http.internal:3128 --https-proxy=docker.for.mac.http.internal:3129"
      msg " !! IMPORTANT !! - If router and docker registry are not running: create admin user with this script, login and restart router and docker registry"
    ;;
    docker-down)
      echo "Stop cluster"
      #oc login -u system:admin
      #oc config set-cluster 127-0-0-1:8443
      oc cluster down
      oc config delete-cluster 127-0-0-1:8443
    ;;
    docker-login-admin)
      oc login -u system:admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
      oc create user admin
      oc adm policy add-cluster-role-to-user cluster-admin admin
      oc login -u admin -p admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;
    # make user admin to be a real admin, must be run on a master node
    vagrant-acl-for-admin)
      vagrant ssh ${OPENSHIFT_VAGRANT_MASTER} -c "oc adm policy add-cluster-role-to-user cluster-admin admin"
    ;;
    # User admin password admin created at install time
    vagrant-login-admin)
      oc login -u admin -p admin --server=${OPENSHIFT_VAGRANT_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;
    #
    # Common tasks
    #

    create-user-developer)
      oc create user developer
      oc login --username=developer --password=developer
    ;;

    get-info)
      msg " * Get cluster user, roles and scc info"
      cmd "oc get scc"
      cmd "oc get roleBindings"
      cmd "oc get policyBindings"
      cmd "oc get clusterPolicyBindings"
      cmd "oc get user"
      msg " * Get all objects in current namespace"
      cmd "oc get all --all-namespaces=true "
      echo " To have more details run same commands with oc describe [scc | ...]"
    ;;

    get-default-templates)
      msg " * List default installed templates: https://docs.openshift.org/latest/install_config/imagestreams_templates.html#install-config-imagestreams-templates"
      cmd "oc get is -n openshift"
      cmd "oc get templates -n openshift"
    ;;

    diagnostic)
      oc adm diagnostics
    ;;

    get-all)
      cmd "oc get pv  --show-labels=true --all-namespaces=true"
      cmd "oc get pvc --show-labels=true --all-namespaces=true"
      cmd "oc get serviceaccounts --show-labels=true --all-namespaces=true"
      cmd "oc get all --show-labels=true --all-namespaces=true"
    ;;

    import-docker-image-busy-box)
      oc import-image default/busysbox:latest --from=docker.io/library/busybox:latest --confirm
    ;;

    registry-console-deploy)
      # From https://docs.openshift.org/latest/install_config/registry/deploy_registry_existing_clusters.html#deploying-the-registry-console
      oc create -n default -f https://raw.githubusercontent.com/openshift/openshift-ansible/release-3.9/roles/openshift_hosted_templates/files/v3.9/origin/registry-console.yaml
      oc create route passthrough --service registry-console --port registry-console -n default
      oc new-app -n default --template=registry-console \
          -p OPENSHIFT_OAUTH_PROVIDER_URL="https://${OPENSHIFT_HOSTNAME}:8443" \
          -p REGISTRY_HOST=$(oc get route docker-registry -n default --template='{{ .spec.host }}') \
          -p COCKPIT_KUBE_URL=$(oc get route registry-console -n default --template='https://{{ .spec.host }}')
    ;;
    registry-console-delete)
      oc delete all -l createdBy=registry-console-template -n default
      oc delete OAuthClient cockpit-oauth-client
    ;;


    #
    # --- Custom examples ---
    #

    example-deploy-scala-hello-world)
      oc login -u developer
      echo " * Delete scala-hello-world"
      #oc delete
      oc delete template 'sbt-jenkins-pipeline'
      oc delete imagestreams "wildfly"
      oc delete buildconfigs "scala-hello-world-docker"
      oc delete imagestreams,buildconfigs,deploymentconfigs,services,routes "scala-hello-world"

      echo " * Build scala-hello-world"
      oc create -f ${SCRIPT_PATH}/../boilerplates/scala-hello-world/openshift/sbt-jenkins-pipeline.yaml
      oc new-app sbt-jenkins-pipeline # build, export artifact to anothe image, and deploy
      oc start-build scala-hello-world
      openshiftWebConsole

    ;;


    #
    # --- Openshift examples ---
    #
    example-deploy-nfs)
      oc create -f ${SCRIPT_PATH}/templates/nfs-pv.yml
      oc create -f ${SCRIPT_PATH}/templates/nfs-pvc.yml
      #oc create -f ${SCRIPT_PATH}/templates/nfs-nginx.yml
      oc create -f ${SCRIPT_PATH}/templates/nfs-rhel.yml
    ;;
    example-delete-nfs)
      oc delete -f ${SCRIPT_PATH}/templates/nfs-pv.yml
      oc delete -f ${SCRIPT_PATH}/templates/nfs-pvc.yml
      #oc delete -f ${SCRIPT_PATH}/templates/nfs-nginx.yml
      oc delete -f ${SCRIPT_PATH}/templates/nfs-rhel.yml
    ;;    
    example-deploy-nodejs)
      echo " * Start node example from git repo (use s2i)"
      oc new-app https://github.com/openshift/nodejs-ex -l name=nodejs-example
      echo " * Follow build logs"
      oc logs -f bc/nodejs-ex
      echo " * Expose route to outside"
      oc expose svc/nodejs-ex
    ;;
    example-delete-nodejs)
      # use label selector to delete
      echo " * Delete all objects"
      oc delete all -l name=nodejs-example
    ;;
    example-deploy-nginx)
      echo " * Start node example from git repo (use s2i)"
      oc new-app -f https://raw.githubusercontent.com/sclorg/nginx-ex/master/openshift/templates/nginx.json -l name=nginx-example
      echo " * Follow build logs"
      oc logs -f bc/nginx-example
      echo " * Expose route to outside"
      oc expose svc/nodejs-ex
    ;;
    example-delete-nginx)
      # use label selector to delete
      echo " * Delete all objects"
      oc delete all -l name=nginx-example
    ;;
    example-deploy-local-storage)
      echo " * Build and deploy local storage template -> https://github.com/openshift/origin/blob/master/examples/storage-examples/local-storage-examples/local-nginx-pod.json"
      oc login -u system:admin
      echo " * Add security context to developer (required to create volumes)"
      # list security context $oc get scc
      #
      oc adm policy add-scc-to-user hostmount-anyuid developer
      oc login --username=developer --password=developer
      oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/storage-examples/local-storage-examples/local-nginx-pod.json
    ;;
    example-delete-local-storage)
      echo "to do..."
    ;;

    *) usage; exit 0 ;;
  esac

}


#
# --------- Openshift --- Install ----------------------------------------------
#
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

function openshiftInstallDocker() {
  # Prerequisites
  command -v docker >/dev/null 2>&1 || {
    echo " * ERROR: install docker and retry!"
    exit 1
  }
  command -v socat >/dev/null 2>&1 || {
    echo " * Install brew socat"
    brew install socat
  }
  echo " * Edit docker insecure registry and add '172.30.0.0/16' "
}

function openshiftWebConsole(){
  URL=$( oc config current-context | tr '\t' ' ' |  sed -n 's/[^\/]*\/\([^/]*\)\/.*/\1/p' | tr '-' '.')
  echo ""
  echo " * Check build at https://${URL}"
  echo ""
  #open https://${URL}
}


parseCli "$@"

cd ${CURRENT_PATH}






