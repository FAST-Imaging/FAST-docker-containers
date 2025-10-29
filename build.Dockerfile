FROM ubuntu:18.04

# Build type: Release or Debug
ARG BUILD_TYPE=Release

SHELL ["/bin/bash", "-c"]

# Install a newer version of cmake
# and compiler (g++), required dev packages
# and python3 stuff for python wheel build
RUN apt-get update && \
    apt install -y sudo && \
    sudo apt install -y gpg wget software-properties-common lsb-release ca-certificates && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ bionic main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null && \
    sudo apt-get update && \
    sudo rm /usr/share/keyrings/kitware-archive-keyring.gpg && \
    sudo apt-get install kitware-archive-keyring && \
    sudo apt install -y cmake && \
    sudo apt install -y g++ patchelf libx11-dev libgl-dev libpng16-16 git && \
    sudo apt install -y pkgconf libusb-1.0-0-dev && \
    sudo apt install -y python3 libpython3-dev python3-pip python3-setuptools && \
    sudo pip3 install --upgrade pip && \
    pip3 install pylddwrap==1.2.* wheel && \
    sudo apt clean && \
    sudo apt autoremove;

ENV BUILD_TYPE=$BUILD_TYPE

COPY checkout_and_build_fast.sh /app/
CMD ["./app/checkout_and_build_fast.sh"]