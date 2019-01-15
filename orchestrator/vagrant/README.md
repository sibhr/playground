# Vagrant

## Install

- enter first server `vagrant ssh centos-01`
- sudo `sudo su`
- `cd /home/vagrant/openshift-ansible`
- **IMPORTANT!** `git checkout openshift-ansible-3.11.68-1`
- test inventory `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/ping.yml`
- check ansible `ansible-playbook -i /opt/host-3-11-cluster.localhost /opt/openshift-ansible/playbooks/prerequisites.yml`
- deploy cluster `ansible-playbook -i /opt/ansible/host-3-11-cluster.localhost /opt/openshift-ansible/playbooks/deploy_cluster.yml`

## Run

`open https://centos-01:8443`

## Notes

