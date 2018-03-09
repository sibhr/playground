# Vagrant

Install vagrant <https://www.vagrantup.com>

Run `vagrant up`

## Ansible

Vagrant supports ansible provisioner

Vagrant generate an inventory files in `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`

This inventory works from local terminal

`ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provisioning/ping.yml`

## Cockpit

Open `https://centos-01:9090` and `https://centos-02:9090/users`
Login with user: vagrant and password: vagrant

## To do

- Install gitlab
- Install ldap server
- Enable centos ssh login with ldap credentials
- Patch cockpit to show more then 10 service log files
- Upgrade service to run with non root user