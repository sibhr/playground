
# Openshift

Docs <https://docs.openshift.com/container-platform/3.11/welcome/index.html>

Credits goes to <https://github.com/samir-saad/openshift-origin-multi-node-cluster/blob/master/ansible/ansible-hosts.yaml>

## Tasks

Uninstall `ansible-playbook -i ansible/hosts-3-9.localhost openshift-ansible/playbooks/adhoc/uninstall.yml`

## NFS example

Create nfs folder for pv storage [./ansible/nfs-exports.yml](./ansible/nfs-exports.yml)

Run nfs-example `./scripts/openshift.sh create-nfs-example`

## Tools

Enable shell completion `source <(oc completion bash)` or `source <(oc completion zsh)`

### Docker images

Openshift CLI image openshift/origin-cli <https://hub.docker.com/r/openshift/origin-cli/> It is based on CentOS

## Minishift

Docker registry login `docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)`