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

declare OS_CMD="oc "
declare OPENSHIFT_VAGRANT_MASTER="okd-master-01.vm.local"
declare OPENSHIFT_VAGRANT_CLUSTER_URL="https://${OPENSHIFT_VAGRANT_MASTER}:8443"
declare OPENSHIFT_VERSION="3.11"
declare OPENSHIFT_EXAMPLES_NAMESPACE="examples"

declare SCRIPT_PATH; SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
declare CURRENT_PATH; CURRENT_PATH=$( pwd )

# Check platform
declare PLATFORM; PLATFORM=$(uname)
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
    #val="$2"
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
  echo "               minishift: minishift-upgrade, minishift-up, minishift-login-admin, minishift-info, minishift-clock"
  echo "               docker: docker-up, docker-down, docker-login-admin"
  echo "               vagrant: vagrant-create-user-admin, vagrant-open-web-ui, vagrant-login-admin"
  echo "               common: create-user-developer, get-auth, get-all, diagnostic, create-example-namespaces"
  echo "               registry-console: registry-console-deploy, registry-console-delete"
  echo "               examples: import-docker-image-busy-box"
  echo "               "
  echo "               "
  echo
  echo
  echo
}


#
# ---------- Openshift ----------------------------------------------------------
#


function openshift() {

  case $PARAM_OPENSHIFT in

    #
    # ---------- Vagrant ----------
    #     

    vagrant-open-web-ui)
      open ${OPENSHIFT_VAGRANT_CLUSTER_URL}
    ;;
    vagrant-create-user-admin)
      TMP=$( pwd )
      cd "${SCRIPT_PATH}/vagrant" || echo "ERROR: Folder ${SCRIPT_PATH}/vagrant not found..."
      vagrant ssh ${OPENSHIFT_VAGRANT_MASTER} -c "sudo ${OS_CMD} create user admin && sudo ${OS_CMD} adm policy add-cluster-role-to-user cluster-admin admin"
      cd "${TMP}" || echo "ERROR: Folder ${TMP} not found..."
    ;;
    # User admin password admin created at install time
    vagrant-login-admin)
      ${OS_CMD} login -u admin -p admin --server=${OPENSHIFT_VAGRANT_CLUSTER_URL} --insecure-skip-tls-verify --loglevel 5
      echo "Export this context: export OS_CONTEXT=$( ${OS_CMD} whoami -c)"
    ;;

    #
    # ---------- Common tasks ----------
    # 
    create-example-namespaces)
      ${OS_CMD} new-project "${OPENSHIFT_EXAMPLES_NAMESPACE}"
      oc project "${OPENSHIFT_EXAMPLES_NAMESPACE}"
    ;;

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
    docker-registry-login)
      declare DOCKER_REGISTRY_ROUTE=docker-registry-default.oct.rnd.unicredit.eu
      declare OS_USER=$(${OS_CMD} whoami)
      declare OS_TOKEN=$(${OS_CMD} whoami -t)
      docker login -p "${OS_TOKEN}" -u "${OS_USER}"  ${DOCKER_REGISTRY_ROUTE}
    ;;
    # Only for openshift oc cli
    import-docker-image-busy-box)
      setEnvContext
      ${OS_CMD} import-image default/busysbox:latest --from=docker.io/library/busybox:latest --confirm -n "${OPENSHIFT_EXAMPLES_NAMESPACE}"
    ;;

    #
    # ---------- registry console ----------
    # 
    registry-console-deploy)
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
          -p REGISTRY_HOST="$(${OS_CMD} get route docker-registry -n default --template='{{ .spec.host }}')" \
          -p COCKPIT_KUBE_URL="$(${OS_CMD} get route registry-console -n default --template='https://{{ .spec.host }}')"
    ;;

    registry-console-delete)
      setEnvContext
      ${OS_CMD} delete all -l createdBy=registry-console-template -n default
      ${OS_CMD} delete OAuthClient cockpit-oauth-client
    ;;
    #
    # ---------- Custom examples ----------
    #

    # --- rook ---
    # 
    # Common issues:
    #    If mon deploymant report an error on "node selector" delete mode deployment, operator will restart it 
    #    https://github.com/rook/rook/issues/2262#issuecomment-460898915
    #
    example-rook-delete)
      # From https://rook.github.io/docs/rook/v1.0/openshift.html
      # Files cloned from https://github.com/rook/rook/tree/v1.0.1/cluster/examples/kubernetes/ceph
      oc delete -f "${SCRIPT_PATH}/examples/rook/dashboard-external-https.yaml"
      oc delete -f "${SCRIPT_PATH}/examples/rook/toolbox.yaml"
      oc delete -f "${SCRIPT_PATH}/examples/rook/storageclass.yaml"
      oc delete -f "${SCRIPT_PATH}/examples/rook/cluster-test.yaml"
      oc delete -f "${SCRIPT_PATH}/examples/rook/operator-openshift.yaml"
      oc delete -f "${SCRIPT_PATH}/examples/rook/common.yaml"
      oc label node okd-worker-01.vm.local role-
      oc label node okd-worker-02.vm.local role-
      oc label node okd-worker-03.vm.local role-
      # delete data on vm
      export ANSIBLE_HOST_KEY_CHECKING=False && ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory ansible/rook-clean-data.yml
    ;;
    example-rook-create)
      # From https://rook.github.io/docs/rook/v1.0/openshift.html
      # TODO: get worker list from oc get nodes...
      oc label node okd-worker-01.vm.local role=storage-node
      #oc label node okd-worker-02.vm.local role=storage-node
      #oc label node okd-worker-03.vm.local role=storage-node
      oc create -f "${SCRIPT_PATH}/examples/rook/common.yaml"
      oc create -f "${SCRIPT_PATH}/examples/rook/operator-openshift.yaml"
      oc create -f "${SCRIPT_PATH}/examples/rook/cluster-test.yaml"
      #oc create -f "${SCRIPT_PATH}/examples/rook/storageclass.yaml"
      #oc create -f "${SCRIPT_PATH}/examples/rook/dashboard-external-https.yaml"
      #oc create -f "${SCRIPT_PATH}/examples/rook/toolbox.yaml"
    ;;
    example-rook-dashboard-open)
      # see https://rook.github.io/docs/rook/v1.0/ceph-dashboard.html
      PSW=$( oc -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo )
      echo "Login with user 'admin' and password '${PSW}'"
      ROUTE=$( oc get route rook-ceph-mgr-dashboard-external-https  -o jsonpath='{.spec.host}' -n "rook-ceph" )
      open "https://${ROUTE}"
    ;;
    example-rook-test-pod-deploy)
      
    ;;
    example-rook-info)
      ${OS_CMD} -n rook-ceph get pod
    ;;
    # --- s2i python-web-server --- 
    example-s2i-python-web-server-deploy)  
      ${OS_CMD} create -f "${SCRIPT_PATH}/examples/s2i-python-web-server/openshift.yaml" -n "${OPENSHIFT_EXAMPLES_NAMESPACE}"
    ;;
    example-s2i-python-web-server-delete)
      ${OS_CMD} delete -f "${SCRIPT_PATH}/examples/s2i-python-web-server/openshift.yaml" -n "${OPENSHIFT_EXAMPLES_NAMESPACE}"
    ;;
    example-s2i-python-web-server-info)
      ${OS_CMD} describe -f "${SCRIPT_PATH}/examples/s2i-python-web-server/openshift.yaml" -n "${OPENSHIFT_EXAMPLES_NAMESPACE}"
    ;;
    example-s2i-python-web-server-console)
      open "${OPENSHIFT_VAGRANT_CLUSTER_URL}/console/project/examples/overview"
      ROUTE=$( oc get route s2i-python-web-server  -o jsonpath='{.spec.host}' -n "${OPENSHIFT_EXAMPLES_NAMESPACE}" )
      open "http://${ROUTE}"
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
      ${OS_CMD} new-app -f "https://raw.githubusercontent.com/openshift/origin/release-${OPENSHIFT_VERSION}/examples/quickstarts/django-postgresql-persistent.json" -l name=django-example
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

    # From https://github.com/openshift/origin/blob/release-${OPENSHIFT_VERSION}/examples/quickstarts/nginx.json
    example-nginx-deploy)
      setEnvContext
      echo " * Start node example from git repo (use s2i)"
      ${OS_CMD} new-app -f "https://raw.githubusercontent.com/openshift/origin/release-${OPENSHIFT_VERSION}/examples/quickstarts/nginx.json" -l name=nginx-example
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
      echo " * Build and deploy local storage template -> https://github.com/openshift/origin/tree/release-${OPENSHIFT_VERSION}/examples/storage-examples/host-path-examples"
      echo "TO DO ...."
    ;;

    *) usage; exit 0 ;;
  esac

}

function setEnvContext(){
  if [[ -n "${OS_CONTEXT}" ]]; then
    echo "!!! Found OS_CONTEXT env: ${OS_CONTEXT} !!!"
    USER=$(${OS_CMD} whoami)
    USER_FROM_CONTEXT=$( echo "${OS_CONTEXT}"  | cut -d/ -f3 )
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

cd "${CURRENT_PATH}" || .




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

