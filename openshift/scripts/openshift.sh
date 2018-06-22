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
declare OPENSHIFT_MASTER="centos-01"
declare OPENSHIFT_CLUSTER_URL="https://${OPENSHIFT_MASTER}:8443"
declare OPENSHIFT_DOCKER_CLUSTER_URL="https://127.0.0.1:8443"

# Set last version to solve issue https://github.com/openshift/origin/pull/13204
declare OPENSHIFT_CLUSTER_DOCKER_VERSION="v3.9.0"

function openshift() {
  case $PARAM_OPENSHIFT in
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
      #oc config delete-cluster 127-0-0-1:8443
    ;;
    docker-login)
      oc login -u system:admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
      oc create user admin
      oc adm policy add-cluster-role-to-user cluster-admin admin
      oc login -u admin -p admin --server=${OPENSHIFT_DOCKER_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;
    # make user admin to be a real admin, must be run on a master node
    acl-for-admin)
      vagrant ssh ${OPENSHIFT_MASTER} -c "oc adm policy add-cluster-role-to-user cluster-admin admin"
    ;;
    # User admin password admin created at install time
    login-admin)
      oc login -u admin -p admin --server=${OPENSHIFT_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
    ;;

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
      cmd "oc get all"
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
      cmd "oc get pv  --show-labels=true"
      cmd "oc get pvc --show-labels=true"
      cmd "oc get serviceaccounts --show-labels=true"
      cmd "oc get all --show-labels=true"
    ;;

    import-docker-image-busy-box)
      oc import-image tools/busysbox:latest --from=docker.io/library/busybox:latest --confirm
    ;;

    #
    # --- Custom examples ---
    #

    example-scala-hello-world)
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
    create-nfs-example)
      oc create -f templates/nfs-pv.yml
      oc create -f templates/nfs-pvc.yml
      #oc create -f templates/nfs-nginx.yml
      oc create -f templates/nfs-rhel.yml
    ;;
    delete-nfs-example)
      oc delete -f templates/nfs-pv.yml
      oc delete -f templates/nfs-pvc.yml
      #oc delete -f templates/nfs-nginx.yml
      oc delete -f templates/nfs-rhel.yml
    ;;    
    create-example-nodejs)
      echo " * Start node example from git repo (use s2i)"
      oc new-app https://github.com/openshift/nodejs-ex -l name=nodejs-example
      echo " * Follow build logs"
      oc logs -f bc/nodejs-ex
      echo " * Expose route to outside"
      oc expose svc/nodejs-ex
    ;;
    delete-example-nodejs)
      # use label selector to delete
      echo " * Delete all objects"
      oc delete all -l name=nodejs-example
    ;;
    create-example-nginx)
      echo " * Start node example from git repo (use s2i)"
      oc new-app -f https://raw.githubusercontent.com/sclorg/nginx-ex/master/openshift/templates/nginx.json -l name=nginx-example
      echo " * Follow build logs"
      oc logs -f bc/nginx-example
      echo " * Expose route to outside"
      oc expose svc/nodejs-ex
    ;;
    delete-example-nginx)
      # use label selector to delete
      echo " * Delete all objects"
      oc delete all -l name=nginx-example
    ;;
    example-local-storage-build)
      echo " * Build and deploy local storage template -> https://github.com/openshift/origin/blob/master/examples/storage-examples/local-storage-examples/local-nginx-pod.json"
      oc login -u system:admin
      echo " * Add security context to developer (required to create volumes)"
      # list security context $oc get scc
      #
      oc adm policy add-scc-to-user hostmount-anyuid developer
      oc login --username=developer --password=developer
      oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/storage-examples/local-storage-examples/local-nginx-pod.json
    ;;


    #
    # --- frameworks ---
    #
    gitlab-deploy)
      GITLAB_PROJECT=gitlab
      GITLAB_SA=gitlab
      #oc adm policy add-scc-to-group anyuid system:authenticated
      oc new-project ${GITLAB_PROJECT}
      oc project ${GITLAB_PROJECT}
      # create service account
      oc create sa ${GITLAB_SA}
      # This pod run as root
      oc adm policy add-scc-to-user anyuid system:serviceaccount:${GITLAB_PROJECT}:${GITLAB_SA}
      # Allow gitlab sa to admin project gitlab (TO BE CHECKED!!!)
      oc policy add-role-to-user admin system:serviceaccounts:${GITLAB_PROJECT}:${GITLAB_SA}
      oc new-app -f templates/gitlab-pod.yml --param=APPLICATION_HOSTNAME=gitlab.127.0.0.1.nip.io --param=SERVICE_ACCOUNT=${GITLAB_SA}
      # vagrant oc create -f templates/gitlab-pod.yml --param=APPLICATION_HOSTNAME=gitlab.192.168.50.101.nip.io
      #oc adm policy add-scc-to-user anyuid system:serviceaccount:default:gitlab-user
    ;;
    gitlab-delete)
      GITLAB_PROJECT=gitlab
      GITLAB_SA=gitlab
      oc project ${GITLAB_PROJECT}
      oc delete all -l createdBy=gitlab-template

    ;;
    gitlab-create-project)
      oc 
    ;;
    # TODO need to create nfs volume manually since dynamic volume claim doesn't support nfs
    gitlab-full-deploy)
      oc create -f  templates/gitlab-volumes.yml
      oc new-app --file=${SCRIPT_PATH}/../templates/gitlab.json \
         -l rndid=gitlab-ce \
         --param=APPLICATION_HOSTNAME=gitlab.192.168.50.101.nip.io \
         --param=GITLAB_ROOT_PASSWORD=password
      # Allow to run docker with root user 
      # https://about.gitlab.com/2016/06/28/get-started-with-openshift-origin-3-and-gitlab/#current-limitations
      oc adm policy add-scc-to-user anyuid system:serviceaccount:default:gitlab-ce-user
    ;;
    gitlab-full-delete)
      oc delete -f  templates/gitlab-volumes.yml
      oc delete all -l rndid=gitlab-ce
      oc delete pvc -l rndid=gitlab-ce
      oc delete serviceaccounts gitlab-ce-user
    ;;

    *) usage; exit 0 ;;
  esac

}


#
# --------- Openshift --- Install ----------------------------------------------
#

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






