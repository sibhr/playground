# Gitlab k8s integration

Internal cluster url <https://openshift.default.svc.cluster.local>

CA certificate (openshift docker image) `docker exec -t -i $CONTAINER_ID /bin/sh` and  `cat ./var/lib/origin/openshift.local.config/master/ca.crt`

Default helm yaml <https://gitlab.com/gitlab-org/gitlab-ce/tree/master/vendor>

Custom AutoDevops <http://gitlab.127.0.0.1.nip.io/help/topics/autodevops/index.md#customizing>

## Enable ingress

Inside gitlab docker image (use `oc rsh $GITLAB_POD_ID`) edit rbac section in `./opt/gitlab/embedded/service/gitlab-rails/vendor/ingress/values.yaml`

```
rbac:
  create: true
```

Ingress expose traffic with `external service ip` <https://docs.openshift.com/container-platform/3.9/dev_guide/expose_service/expose_internal_ip_service.html>

Check External ip in `services\ingress-nginx-ingress-controller` section <https://127.0.0.1:8443/console/project/gitlab-managed-apps/browse/services/ingress-nginx-ingress-controller?tab=details>

**There is no route from host machine to this subnet in docker virtual machine** Need to log to origin docker or to docker vm to test if it is working!

Ingress rbac error <https://gitlab.com/gitlab-org/gitlab-ce/issues/46969#install-ingress>