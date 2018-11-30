# FROM openshift/base-centos7 #Contains default user...
FROM centos:centos7

ENV APP_ROOT=/opt/app \
    USER_NAME=default \
    USER_UID=10001

WORKDIR ${APP_ROOT}
ENV HOME=${APP_ROOT}

RUN mkdir -p ${APP_ROOT}/bin && \
    chmod -R ug+x ${APP_ROOT}/bin && sync && \
    useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin -c "${USER_NAME} user" ${USER_NAME} && \
    chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

#python -m SimpleHTTPServer 8000
CMD /bin/bash