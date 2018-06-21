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