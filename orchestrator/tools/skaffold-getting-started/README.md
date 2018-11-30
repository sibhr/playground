# Skaffold

Skaffold <https://github.com/GoogleContainerTools/skaffold>

## Install

`brew install skaffold`

## Test

Skaffold doesn't support custom docker registry now. Workaround consists to force docker image tag to latest.

Edit [skaffold.yaml](./skaffold.yaml) and set docker registry to external openshift registry route

Edit [k8s-pod.yaml](./k8s-pod.yaml) and set docker registry to internal openshift registry ip or hostname