FROM centos:7.6.1810 

ENV LC_ALL=en_US.UTF-8 \
    # Set timezone
    TZ='Europe/Rome'

# Create custom user 
ENV APP_ROOT=/opt/app \
    USER_NAME=appuser \
    USER_UID=10001
WORKDIR ${APP_ROOT}
ENV HOME=${APP_ROOT}
RUN mkdir -p ${APP_ROOT}/bin && \
    chmod -R ug+x ${APP_ROOT}/bin && sync && \
    useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin -c "${USER_NAME} user" ${USER_NAME} && \
    chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

# Update OS and Install Jupyterlab
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && yum -y install epel-release \
    && yum -y update \
    && yum -y install  https://downloads.rclone.org/rclone-current-linux-amd64.rpm \
    && yum -y install  git  python36 python36-pip  \
    && yum clean all \
    && rm -rf /var/cache/yum \
    # Install Jupyterlab
    && pip3 --no-cache-dir install --upgrade pip \
    && pip3 --no-cache-dir install jupyterlab scikit-learn scikit-image pandas s3fs minio \
    && mkdir -p ${APP_ROOT}/notebooks ${APP_ROOT}/.jupyter \
    && touch ${APP_ROOT}/.jupyter/jupyter_notebook_config.py

USER ${USER_NAME}

CMD cd ${APP_ROOT}/notebooks && jupyter lab --no-browser --ip 0.0.0.0 --allow-root 

# Notes:
# Local run: docker run -p 8888:8888  -t -i image_name
