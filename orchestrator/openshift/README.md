
# Openshift

Test openshift with:

- [vagrant cluster](./vagrant/README.md) - Install a full cluster with official ansible
- [minishift and docker cluster up](./scripts)
- [common examples](./examples) - deploy app to openshift and kubernetes

## Resources

Docs <https://docs.openshift.com/container-platform/3.11/welcome/index.html>
Credits goes to <https://github.com/samir-saad/openshift-origin-multi-node-cluster/blob/master/ansible/ansible-hosts.yaml>

## CLI

- Install on mac os x with brew `brew install openshift-cli`
- run CLI from docker image openshift/origin-cli <https://hub.docker.com/r/openshift/origin-cli/> It is based on CentOS
- Enable shell completion `source <(oc completion bash)` or `source <(oc completion zsh)`
- Openshift CLI image openshift/origin-cli from <https://hub.docker.com/r/openshift/origin-cli/> It is based on CentOS

## Examples

See [openshift.sh](./openshift.sh)

- [rook cluster](./examples/rook)
- [s2i-python-web-server](./examples/s2i-python-web-server)

## TODO

- local-provisioner https://docs.openshift.com/container-platform/3.11/install_config/configuring_local.html#local-volume-configure-local-provisioner
- disable swap `swapoff -a` 

## ISSUES

- if master is slow or you get a ui disconnection, master is overused, disable swap may help `swapoff -a`
