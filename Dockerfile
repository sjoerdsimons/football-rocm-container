# syntax=docker/dockerfile:1

FROM archlinux:base-devel-20260614.0.544538

SHELL ["/bin/bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG GST_ML_REMOTE_URL="https://github.com/lubosz/gst-python-ml.git"
ARG GST_ML_BRANCH="soccer-analyzer"
ARG CODE_PATH=/root/src
ARG GST_ML_PATH=${CODE_PATH}/gst-python-ml

# Not a minimal selection
RUN pacman -Syy && pacman -S --noconfirm \
    git \
    onnxruntime-opt-rocm \
    python-onnxruntime-opt-rocm \
    gst-python \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    python-virtualenv \
    python-pytorch-opt-rocm \
    gst-plugins-bad-libs


# in case i forgot to add it here
# (.venv) [root@14748dc9b886 gst-python-ml]# history | grep pacman
#     1  pacman -Syy
#     2  pacman -S --noconfirm git     onnxruntime-opt-rocm     python-onnxruntime-opt-rocm     gst-python     gst-plugins-base     python-virtualenv     python-pytorch-opt-rocm
#    20  pacman -Ss gst
#    21  pacman -S gst-plugins-bad-libs
#    30  pacman -S gst-plugins-bad gst-plugins-ugly
#    31  pacman -S gst-plugins-bad
#    33  pacman -S gst-plugins-ugly
#    35  pacman -Ss gst
#    36  pacman -Ss gst | grep installed
#    37  pacman -S gst-plugins-good
#    53  history | grep pacman


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


# build torchvision: something like that
# pacman -S base-devel
# git clone https://aur.archlinux.org/python-torchvision-rocm.git
# cd python-torchvision-rocm
# makepkg -si