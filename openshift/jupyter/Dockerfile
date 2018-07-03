#
# Nvidia docker images https://github.com/NVIDIA/nvidia-docker/wiki/Frequently-Asked-Questions#do-you-provide-official-docker-images
#

ARG CENTOS_VERSION="7"
ARG CUDA_VERSION="8.0"
ARG CUDNN_VERSION="7"
#FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-centos${CENTOS_VERSION}
FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-runtime-centos${CENTOS_VERSION}

### Setup user for build execution and application runtime
ENV APP_ROOT=/opt/jupyter \
    USER_NAME=default \
    USER_UID=10001


### Install python

ENV PYTHON_VERSION="3.6.4"

RUN echo -e "\n ### ### ### Python 3 from source  ### ### ###  \n" && \
    yum -y install zlib-devel gcc make openssl openssl-devel sqlite-devel && \
    curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz | tar xvz -C /opt && \
    cd /opt/Python-${PYTHON_VERSION} && \
    sed -i -e 's|#SSL=/usr/local/ssl|SSL=/usr/bin/openssl|g' Modules/Setup.dist && \
    ./configure && \
    make && \
    make install && \
    yum -y remove zlib-devel gcc make openssl openssl-devel sqlite-devel && \
    rm -rf /opt/Python-${PYTHON_VERSION} && \
    # Allow random user to install packages \
    chown -R ${USER_UID}:0 /usr/local/lib/python3.6 && \
    chmod -R g=u /usr/local/lib/python3.6   && \
    chown -R ${USER_UID}:0 /usr/local/bin && \
    chmod -R g=u /usr/local/bin

WORKDIR ${APP_ROOT}
ENV HOME=${APP_ROOT}

RUN pip3 install --upgrade pip && \
    pip3 install jupyter && \
    pip3 install torch torchvision && \
    jupyter notebook --generate-config && \
    echo "{ \"NotebookApp\": { \"password\": \"sha1:85752bb87e1b:99d92e363277fcc0a25e82accb646775e1e03dea\" } } " > ${APP_ROOT}/.jupyter/jupyter_notebook_config.json

### Containers should NOT run as root as a good practice

#ENV PATH=${APP_ROOT}/bin:${PATH} HOME=${APP_ROOT}
#COPY bin/ ${APP_ROOT}/bin/
RUN mkdir -p ${APP_ROOT}/bin && \
    chmod -R ug+x ${APP_ROOT}/bin && sync && \
    useradd -l -u ${USER_UID} -r -g 0 -d ${APP_ROOT} -s /sbin/nologin -c "${USER_NAME} user" ${USER_NAME} && \
    chown -R ${USER_UID}:0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT}

USER ${USER_UID}