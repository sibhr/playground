FROM centos:7.6.1810 

ENV LC_ALL=en_US.UTF-8

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

# Install Dask and jupyter notebook
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && yum -y install epel-release \
    && yum -y update \
    && yum -y install gcc git graphviz python36 python36-pip  \
    && yum -y install python36-devel nodejs\
    && pip3 install --upgrade pip \
    && pip3 install "dask[complete]" gcsfs jupyterlab \
    && pip3 install numpy h5py scipy toolz bokeh dask distributed notebook matplotlib Pillow pandas pandas-datareader tables \
    && pip3 install scikit-learn scikit-image snakeviz ujson graphviz pip s3fs fastparquet dask-ml graphviz cachey dask-kubernetes  \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN mkdir -p /opt/app/.jupyter && touch /opt/app/.jupyter/jupyter_notebook_config.py

# Install dask stats dashboard proxy
RUN pip3 install ipywidgets dask_labextension jupyter-server-proxy\
&& jupyter labextension install dask-labextension \
&& jupyter labextension install @jupyter-widgets/jupyterlab-manager \
&& jupyter serverextension enable --py jupyter_server_proxy

# Download examples
RUN mkdir ${APP_ROOT}/notebooks \
    && cd ${APP_ROOT}/notebooks \
    && git clone http://github.com/dask/dask-tutorial \
    && git clone https://github.com/dask/dask-examples.git 

CMD cd ${APP_ROOT}/notebooks && jupyter lab --no-browser --ip 0.0.0.0 --allow-root 

# Notes:
# Local run: docker run -p 8888:8888 -p 8787:8787 -t -i dask
