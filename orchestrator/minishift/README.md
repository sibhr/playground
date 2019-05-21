# Minishift and docker cluster

Openshift can run with:

- `oc cluster up`
- minishift 

## Minishift

Docker registry login `docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)`