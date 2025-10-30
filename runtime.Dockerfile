ARG BASE_IMAGE=ubuntu:24.04

FROM $BASE_IMAGE

ARG FAST_VERSION=latest
ARG OPENCL_PLATFORM=pocl
ARG VIRTUALGL=false
ARG TYPE
ARG X_SERVER=xvfb
ARG VGL_VERSION=3.1.4

SHELL ["/bin/bash", "-c"]

# ============= Validate arguments
RUN if [ "${OPENCL_PLATFORM}" != "pocl" ] && \
       [ "${OPENCL_PLATFORM}" != "intel" ] && \
       [ "${OPENCL_PLATFORM}" != "nvidia" ]; then \
        echo "Error: build-arg OPENCL_PLATFORM must be 'pocl', 'intel' or 'nvidia'." >&2; \
        exit 1; \
    fi; \
    if [ "${TYPE}" != "library" ] && \
       [ "${TYPE}" != "python" ]; then \
        echo "Error: build-arg TYPE must be 'library' or 'python'." >&2; \
        exit 1; \
    fi; \
    if [ "${X_SERVER}" != "xvfb" ] && \
       [ "${X_SERVER}" != "none" ]; then \
        echo "Error: build-arg X_SERVER must be 'xvfb' or 'none'." >&2; \
        exit 1; \
    fi; \
    if [ "${VIRTUALGL}" != "true" ] && \
       [ "${VIRTUALGL}" != "false" ]; then \
        echo "Error: build-arg VIRTUALGL must be 'true' or 'false'." >&2; \
        exit 1; \
    fi

# =============> Install runtime dependencies
RUN apt update && apt install -y \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1  \
    libxcb-render-util0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxcb-shape0 \
    libopengl0 \
    libusb-1.0-0 \
    libglib2.0-0t64 \
    libglx0 \
    libgl1 \
    libsm6

# =============> Install OpenCL platform specific packages
# TODO NVIDIA
RUN if [ "${OPENCL_PLATFORM}" = "pocl" ]; then \
        apt install -y libpocl2t64; \
    elif [ "${OPENCL_PLATFORM}" = "intel" ]; then \
        apt install -y intel-opencl-icd; \
    elif [ "${OPENCL_PLATFORM}" = "nvidia" ]; then \
        apt install -y nvidia-opencl-icd-340; \
    fi

# ==============> Install X server specific packages
RUN if [ "${X_SERVER}" = "xvfb" ]; then \
        apt install -y xvfb; \
    fi

# ==============> Install and setup virtualgl
RUN if [ "${VIRTUALGL}" = "true" ]; then \
        apt-get install -y wget libxtst6 libxv1 libglu1-mesa libegl1 && \
        wget https://github.com/VirtualGL/virtualgl/releases/download/${VGL_VERSION}/virtualgl_${VGL_VERSION}_amd64.deb && \
        dpkg -i virtualgl_${VGL_VERSION}_amd64.deb && \
        ./opt/VirtualGL/bin/vglserver_config -config +s +f +t && \
        rm virtualgl_${VGL_VERSION}_amd64.deb; \
    fi

# ==============> Install FAST according to TYPE and FAST_VERSION
COPY get_latest_fast_version.py /
COPY fast_version.py /
RUN if [ "${TYPE}" = "python" ]; then \
       apt install -y python3 python3-pip python3-venv && \
       python3 -m venv /environment && \
       source /environment/bin/activate && \
       pip install requests && \
       pip install pyfast==$(python fast_version.py $FAST_VERSION) && \
       pip cache purge; \
   else \
       apt install -y python3 python3-pip python3-venv wget libopenslide0 &&\
       python3 -m venv /environment && \
       source /environment/bin/activate && \
       pip install requests && \
       VERSION=$(python fast_version.py $FAST_VERSION) && \
       wget https://github.com/FAST-Imaging/FAST/releases/download/v$VERSION/fast_ubuntu18.04_$VERSION.deb && \
       dpkg -i fast_ubuntu18.04_$VERSION.deb && \
       rm fast_*.deb  \
       deactivate \
       rm -Rf /environment; \
   fi

# ==============> Set environment variables
ENV LD_LIBRARY_PATH=/opt/fast/lib/
ENV TYPE=$TYPE
ENV VIRTUALGL=$VIRTUALGL
ENV X_SERVER=$X_SERVER

# ==============> Cleaning
RUN apt clean && apt autoremove

# ==============> Set init script as entrypoint
COPY entrypoint.sh /init/entrypoint.sh
COPY test_runtime_image.sh /test/test_runtime_image.sh
ENTRYPOINT ["./init/entrypoint.sh"]
CMD ["./test/test_runtime_image.sh"]