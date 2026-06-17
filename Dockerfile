# syntax=docker/dockerfile:1

FROM rocm/onnxruntime:rocm7.2.4_ub24.04_ort1.23_torch2.10.0

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG GST_ML_REMOTE_URL="https://github.com/lubosz/gst-python-ml.git"
ARG GST_ML_BRANCH="soccer-analyzer"
ARG CODE_PATH=/root/src
ARG GST_ML_PATH=${CODE_PATH}/gst-python-ml

# Not a minimal selection
RUN apt-get update && apt-get install -y \
    git \
    python3-virtualenv \
    python3-gst-1.0 \
    libgstreamer-plugins-good1.0-dev \
    python3-cairo-dev \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-python3-plugin-loader \
    gstreamer1.0-plugins-base-apps \
    python3-gi \
    gir1.2-gstreamer-1.0 \
    gir1.2-gst-plugins-bad-1.0 \
    libcairo2 libcairo2-dev \
    libgirepository-2.0-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone the code
RUN mkdir ${CODE_PATH}
RUN cd ${CODE_PATH} && git clone ${GST_ML_REMOTE_URL} -b ${GST_ML_BRANCH}

# Set up venv
RUN bash <<EOF
    cd ${GST_ML_PATH}
    virtualenv --system-site-packages .venv
    source .venv/bin/activate
    pip install .
    # rm Gst cache
    export GST_PLUGIN_PATH=`realpath plugins/`
    rm ~/.cache/gstreamer-1.0/ -Rf
    GST_DEBUG=3 gst-inspect-1.0 python
    pip install supervision
EOF
