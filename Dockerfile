# syntax = docker/dockerfile:1.0-experimental
FROM pytorch/pytorch:1.8.1-cuda11.1-cudnn8-runtime

# working directory
WORKDIR /workspace

# ---------------------------------------------
# Project-agnostic System Dependencies
# ---------------------------------------------
RUN \
    # Install System Dependencies
    apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        wget \
        unzip \
        psmisc \
        vim \
        git \
        ssh \
        curl \
        lshw \
        ubuntu-drivers-common \
        ca-certificates \
        libjpeg-dev \
        libpng-dev && \
    rm -rf /var/lib/apt/lists/* && \
    # Install NVIDIA Driver
    # https://www.linuxbabe.com/ubuntu/install-nvidia-driver-ubuntu-18-04
    # ubuntu-drivers autoinstall && \
    # https://serverfault.com/questions/227190/how-do-i-ask-apt-get-to-skip-any-interactive-post-install-configuration-steps
    # https://stackoverflow.com/questions/38165407/installing-lightdm-in-dockerfile-raises-interactive-keyboard-layout-menu
    # apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    #     nvidia-driver-440 && \
    # rm -rf /var/lib/apt/lists/* && \
    # Install NodeJS
    # https://github.com/nodesource/distributions/blob/master/README.md#deb
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get install -y nodejs

# ---------------------------------------------
# Project-specific System Dependencies
# ---------------------------------------------
RUN \
    # Clone the Apex Module (this requires torch)
    # git clone https://github.com/NVIDIA/apex /workspace/apex && \
    # cd /workspace/apex && \
    # pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./ && \
    # Install Graphviz
    apt-get update && apt-get install -y --no-install-recommends \
        graphviz && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# Build Python depencies and utilize caching
# ---------------------------------------------
COPY ./requirements.txt /workspace/joint-inference/requirements.txt
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r /workspace/joint-inference/requirements.txt && \
    # Jupyter Extensions (https://plot.ly/python/getting-started/):
    # Avoid "JavaScript heap out of memory" errors during extension installation (OS X/Linux)
    export NODE_OPTIONS=--max-old-space-size=4096 && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    # jupyter labextension install @oriolmirosa/jupyterlab_materialdarker --no-build  && \
    jupyter lab build && \
    # Unset NODE_OPTIONS environment variable (OS X/Linux)
    unset NODE_OPTIONS

# upload everything
COPY . /workspace/joint-inference/

# Set HOME
ENV HOME="/workspace/joint-inference"

# ---------------------------------------------
# Project-agnostic User-dependent Dependencies
# ---------------------------------------------
RUN \
    # Install Awesome vimrc
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime && \
    sh ~/.vim_runtime/install_awesome_vimrc.sh && \
    # NLTK
    python -m nltk.downloader punkt

# Reset Entrypoint from Parent Images
# https://stackoverflow.com/questions/40122152/how-to-remove-entrypoint-from-parent-image-on-dockerfile/40122750
ENTRYPOINT []

# load bash
CMD /bin/bash