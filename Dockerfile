# Stage 1: Base
FROM nvidia/cuda:12.3.1-base-ubuntu22.04 as base

ARG FOOOCUS_VERSION=2.2.1

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    LOGIN_PASSWORD=M3GATIVE 

USER root

RUN apt update \
   && apt install -y --no-install-recommends \
      curl \
      libgl1 \
      libglib2.0-0 \
      python3-pip \ 
      python-is-python3 \
      git \
      wget \
      tmux \
      nano \
	 && apt clean \
	 && rm -rf /var/lib/apt/lists/*

# Stage 2: Install SD tools
FROM base as setup

WORKDIR /workspace

RUN git clone https://github.com/lllyasviel/Fooocus.git fooocus \
    && cd fooocus \
    && git checkout ${FOOOCUS_VERSION} \
    && pip install -r requirements_docker.txt -r requirements_versions.txt \
    && pip install --no-cache-dir xformers==0.0.22 --no-dependencies

WORKDIR /workspace/fooocus

COPY config/fooocus/auth.json auth.json
COPY config/fooocus/next.json presets/next.json

RUN sed -i "s/replaceme/${LOGIN_PASSWORD}/g" auth.json

# install filebrower
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

COPY config/filebrowser/filebrowser.json /root/.filebrowser.json

RUN filebrowser config init && filebrowser users add admin ${LOGIN_PASSWORD} --perm.admin

WORKDIR /root

COPY scripts/run.sh run.sh

ENTRYPOINT ["/bin/bash", "run.sh"]
