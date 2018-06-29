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
declare OPENSHIFT_HOSTNAME=$(oc config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)

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

function parse() {
  case $PARAM in
    #
    # --- GITLAB DEPLOY  ---
    #
    deploy)
      GITLAB_PROJECT=gitlab
      GITLAB_SA=gitlab
      #oc adm policy add-scc-to-group anyuid system:authenticated
      #oc adm policy add-scc-to-group privileged system:authenticated
      oc new-project ${GITLAB_PROJECT}
      oc project ${GITLAB_PROJECT}
      # create service account
      oc create sa ${GITLAB_SA}
      # This pod run as root
      oc adm policy add-scc-to-user anyuid system:serviceaccount:${GITLAB_PROJECT}:${GITLAB_SA}
      # Allow gitlab sa to admin project gitlab (TO BE CHECKED!!!)
      # DOES NOT WORK!!!!! oc policy add-role-to-user admin system:serviceaccounts:${GITLAB_PROJECT}:${GITLAB_SA}
      oc policy add-role-to-user admin -z ${GITLAB_SA}
      # Get sa token
      TOKEN=$(oc sa get-token gitlab)
      oc new-app --token="${TOKEN}" -f ${SCRIPT_PATH}/deploy/gitlab-pod.yml --param=APPLICATION_HOSTNAME=gitlab.${OPENSHIFT_HOSTNAME}.nip.io --param=SERVICE_ACCOUNT=${GITLAB_SA} -l rndid=gitlab-ce
      #oc adm policy add-scc-to-user anyuid system:serviceaccount:default:gitlab-user
    ;;
    delete)
      GITLAB_PROJECT=gitlab
      GITLAB_SA=gitlab
      oc delete project ${GITLAB_PROJECT}
    ;;

    # # TODO need to create nfs volume manually since dynamic volume claim doesn't support nfs
    # deploy-full)
    #   oc create -f  ${SCRIPT_PATH}/deploy/gitlab-volumes.yml
    #   oc new-app --file=${SCRIPT_PATH}/deploy/gitlab-full.json \
    #      -l rndid=gitlab-ce \
    #      --param=APPLICATION_HOSTNAME=gitlab.192.168.50.101.nip.io \
    #      --param=GITLAB_ROOT_PASSWORD=password
    #   # Allow to run docker with root user 
    #   # https://about.gitlab.com/2016/06/28/get-started-with-openshift-origin-3-and-gitlab/#current-limitations
    #   oc adm policy add-scc-to-user anyuid system:serviceaccount:default:gitlab-ce-user
    # ;;
    # delete-full)
    #   oc delete -f  ${SCRIPT_PATH}/deploy/gitlab-volumes.yml
    #   oc delete all -l rndid=gitlab-ce
    #   oc delete pvc -l rndid=gitlab-ce
    #   oc delete serviceaccounts gitlab-ce-user
    # ;;
    k8s-integration-create)
      oc new-project gitlab-managed-apps
      oc project gitlab-managed-apps
      oc create sa gitlab-managed-apps
      oc policy add-role-to-user admin -z gitlab-managed-apps
      oc adm policy add-scc-to-user anyuid system:serviceaccount:gitlab-managed-apps:gitlab-managed-apps
      oc policy add-role-to-user admin system:serviceaccount:gitlab-managed-apps:default
      oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:gitlab-managed-apps:default
      oc sa get-token gitlab-managed-apps
      # Gitlab runner need to be priviledged
      oc adm policy add-scc-to-group privileged system:authenticated
      # Need to edit hel chart yaml inside gitlab pod running
      
    ;;
    k8s-integration-delete)
      oc delete project gitlab-managed-apps # --force=true --grace-period=0
      oc delete clusterrole.rbac ingress-nginx-ingress
      oc delete clusterrolebindings.rbac ingress-nginx-ingress
    ;;
    helm)
       PORT=$(oc get svc/tiller-deploy -o jsonpath='{.spec.ports[0].port}' -n gitlab-managed-apps)
       OS_HOSTNAME=$(oc config current-context | cut -d/ -f2 | cut -d: -f1 | tr - .)
       TILLER_HOST="${OS_HOSTNAME}:${PORT}"
       oc expose deploy/tiller-deploy --target-port=tiller --type=NodePort --name=tiller -n gitlab-managed-apps
       # need to login to docker, route node ports are exposed on docker0 inteface, but this is not reachable from mac os
    ;;

    #
    # --- GITLAB EXAMPES  ---
    #
    example-deploy-python-web-server)
      oc new-app -f ${SCRIPT_PATH}/examples/python-web-server/os-template.yaml -n gitlab \
      --param=APPLICATION_HOSTNAME=gitlab-example-python-web-server-deploy.${OPENSHIFT_HOSTNAME}.nip.io \
      --param=GITLAB_ENV=staging
    ;;
    example-delete-python-web-server)
      oc delete all -l createdBy=gitlab-ci-python-web-server -n gitlab
    ;;
    *) usage; exit 0 ;;
  esac

}


parseCli "$@"

cd ${CURRENT_PATH}






