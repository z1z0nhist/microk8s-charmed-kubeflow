FROM nvcr.io/nvidia/pytorch:22.12-py3

RUN pip install markupsafe==2.0.1

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /home/jovyan

USER root

RUN pip install jupyter -U && pip install jupyterlab

RUN apt-get update && apt-get install -yq --no-install-recommends \
  apt-transport-https \
  build-essential \
  bzip2 \
  ca-certificates \
  curl \
  g++ \
  git \
  gnupg \
  graphviz \
  locales \
  lsb-release \
  openssh-client \
  sudo \
  unzip \
  vim \
  wget \
  zip \
  emacs \
  python3-pip \
  python3-dev \
  python3-setuptools \
  && apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update
RUN apt-get install -y kubectl
RUN pip install kubeflow-fairing
RUN pip install kfp
RUN pip install kfserving
RUN pip install kubeflow-kale
RUN pip install dill
RUN pip install kubeflow-katib

RUN pip install jupyterlab && \
    jupyter serverextension enable --py jupyterlab --sys-prefix

ARG NB_USER=jovyan

EXPOSE 8888


ENV NB_USER $NB_USER
ENV NB_UID=1000
ENV HOME /home/$NB_USER
ENV NB_PREFIX /

CMD ["sh", "-c", "jupyter lab --notebook-dir=/home/jovyan --ip=0.0.0.0 --no-browser --allow-root --port=8888 --LabApp.token='' --LabApp.password='' --LabApp.allow_origin='*' --LabApp.base_url=${NB_PREFIX}"]
