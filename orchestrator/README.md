# Vagrant

Install vagrant <https://www.vagrantup.com>

Run `vagrant up`

Create snapshot so it is faster to re-install `vagrant snapshot create boot`

## Ansible

Vagrant supports ansible provisioner

Vagrant generate an inventory files in `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`

This inventory works from local terminal

`ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provisioning/ping.yml`

## Openshift

Docs <https://docs.openshift.com/container-platform/3.9/welcome/index.html>

Credits goes to <https://github.com/samir-saad/openshift-origin-multi-node-cluster/blob/master/ansible/ansible-hosts.yaml>

## Tasks

Uninstall `ansible-playbook -i ansible/hosts-3-9.localhost openshift-ansible/playbooks/adhoc/uninstall.yml`

## NFS example

Create nfs folder for pv storage [./ansible/nfs-exports.yml](./ansible/nfs-exports.yml)

Run nfs-example `./scripts/openshift.sh create-nfs-example`

## Tools

Enable shell completion `source <(oc completion bash)` or `source <(oc completion zsh)`

## Gitlab k8s integration

Internal cluster url <https://openshift.default.svc.cluster.local>

CA certificate (openshift docker image) `docker exec -t -i $CONTAINER_ID /bin/sh` and  `cat ./var/lib/origin/openshift.local.config/master/ca.crt`

Default helm yaml <https://gitlab.com/gitlab-org/gitlab-ce/tree/master/vendor>

Custom AutoDevops <http://gitlab.127.0.0.1.nip.io/help/topics/autodevops/index.md#customizing>

### Enable ingress

Inside gitlab docker image (use `oc rsh $GITLAB_POD_ID`) edit rbac section in `./opt/gitlab/embedded/service/gitlab-rails/vendor/ingress/values.yaml`

```
rbac:
  create: true
```

Ingress expose traffic with `external service ip` <https://docs.openshift.com/container-platform/3.9/dev_guide/expose_service/expose_internal_ip_service.html>

Check External ip in `services\ingress-nginx-ingress-controller` section <https://127.0.0.1:8443/console/project/gitlab-managed-apps/browse/services/ingress-nginx-ingress-controller?tab=details>

**There is no route from host machine to this subnet in docker virtual machine** Need to log to origin docker or to docker vm to test if it is working!

Ingress rbac error <https://gitlab.com/gitlab-org/gitlab-ce/issues/46969#install-ingress>

### Docker images

Openshift CLI image openshift/origin-cli <https://hub.docker.com/r/openshift/origin-cli/> It is based on CentOS

## Minishift

Docker registry login `docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)`