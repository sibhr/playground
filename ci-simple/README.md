# CI simple

A simple approach to automate Continuous integration (CI) and continuous development (CD)

Stack:

- Gitlab 
- Open ldap server (optional)
- A bunch of server with CentOS and Cockpit
- Ansible
- A log server with search functionality https://github.com/ekanite/ekanite 

## Vagrant

Install vagrant <https://www.vagrantup.com>

Run `vagrant up`

Connect with ssh `vagrant ssh centos01`

## Ansible

Vagrant supports ansible provisioner

Vagrant generate an inventory files in `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`

This inventory works from local terminal

`ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory provisioning/ping.yml`

## Cockpit

Open `https://centos-01.ci-simple.local:9090/` and `https://centos-02.ci-simple.local:9090/`
Login with user: vagrant and password: vagrant

## Open ldap

Test ldap user login:

- login as vagrant user with `vagrant ssh`
- test local login with `su - user_test`
- enter password `password`

## To do

- Install gitlab
- Install ldap server
- Enable centos ssh login with ldap credentials
- Patch cockpit to show more then 10 service log files
- Upgrade service to run with non root user

## Issues

- Cockpit with ldap crashes with selinux enabled, use permissive policy