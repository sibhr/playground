# Vagrant

Install vagrant <https://www.vagrantup.com>

Run `vagrant up`

## Ansible

Vagrant supports ansible provisioner

Vagrant generate an inventory files in `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`

This inventory works from local terminal

`ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provisioning/ping.yml`

## Install

- enter first server `vagrant ssh okd-master-01.vm.local`
- sudo `sudo su`
- `cd /opt/openshift-ansible`
- **IMPORTANT!** `git checkout openshift-ansible-3.11.68-1`
- test inventory `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/ping.yml`
- check ansible `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/openshift-ansible/playbooks/prerequisites.yml`
- deploy cluster `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/openshift-ansible/playbooks/deploy_cluster.yml`
- uninstall `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/openshift-ansible/playbooks/adhoc/uninstall.yml`

## Run

- open web console <https://okd-master-01.vm.local:8443>

## Notes
