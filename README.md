FAST Docker Containers
====================

This is a repository for creating Docker images for running and building FAST which requires OpenCL and OpenGL, and
in the case of visualization; an X server.

## FAST Runtime Docker
The runtime.Dockerfile has the following build arguments:
- **BASE_IMAGE** - The base image to use in the Docker image. Default: [ubuntu:24.04](https://hub.docker.com/_/ubuntu).
- **FAST_VERSION** - Specify FAST version, e.g. _4.14.0_ or _latest_. Default: latest.
- **OPENCL_PLATFORM** - Which OpenCL platform to install. Valid options are: pocl, intel and nvidia. Default is pocl.
- **TYPE** - Which type of FAST image to create, must be set to either python or library. The python version creates a virtual python environment which pyfast is installed into.
This environment is activated when running the image. The library version installs the FAST debian package to /opt/fast/.
- **VIRTUALGL** - Must be set to true or false, default is false. To render inside the docker image AND get interactive visualization, VirtualGL (VGL) has to be used. 
- **VGL_VERSION** - VGL version to install if VIRTUALGL is enabled. Default: 3.1.4
- **X_SERVER** - Currently only xvfb is supported. This means that OpenGL rendering in FAST is not hardware accelerated.

### Usage examples

#### Library version
Build with TYPE=library, this will install the FAST debian package to /opt/fast/
```bash
docker build . -f runtime.Dockerfile --build-arg TYPE=library -t fast-library
```
```bash
docker run -ti --rm fast-library bash
```

#### Python version
Build with TYPE=python, this will create a virtual python environment in /environment and install pyfast to it.
The environment is activated when the image is started.
```bash
docker build . -f runtime.Dockerfile --build-arg TYPE=python -t fast-python
docker run -ti --rm fast-python python
```

#### Rendering and interactive visualization using host X server
One way to get interactive visualization is give the docker container access to the host X server.
In this case our docker image doesn't need a running X server, and we can build with X_SERVER=none
```bash
docker build . -f runtime.Dockerfile \
    --build-arg TYPE=python \
    --build-arg X_SERVER=none \
    -t fast-python-pocl-no_x
```
Also, note that in this case, the rendering is done outside of docker container.

When running you have to give the docker container access to your X server, which is done by:
- Provide the DISPLAY environment variable which is where the window should appear. By setting it to $DISPLAY it uses your current display.
- Mount the XAUTHORITY path and set the XAUTHORITY environment variable which is needed for docker to get access to your display.
- Mount /tmp/.X11-unix/ which is where the current X11 displays are located.

Example:
```bash
docker run -it --rm \
    -e DISPLAY=$DISPLAY \
    -e XAUTHORITY=$XAUTHORITY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v $XAUTHORITY:$XAUTHORITY:ro \
    fast-python-pocl-no_x \
    systemCheck
```

#### Interactive visualization with VirtualGL
VirtualGL (VGL) is needed to achieve interactive visualization while rendering inside the docker.
Build with **VIRTUALGL=true**, you also need X_SERVER=xvfb which is default:
```bash
docker build . -f runtime.Dockerfile \
    --build-arg VIRTUALGL=true \
    --build-arg TYPE=python \
    -t fast-python-pocl-vgl
```
In this case, VirtualGL will ensure that rendering is done using xvfb inside the docker. While the rendered image
is sent to the host X server, and mouse and keyboard interactions are sent from the host X server to the xvfb server
inside the docker container.

When running you have to give the docker container access to your X server, which is done by:
- Provide the DISPLAY environment variable which is where the window should appear. By setting it to $DISPLAY it uses your current display.
- Mount the XAUTHORITY path and set the XAUTHORITY environment variable which is needed for docker to get access to your display.
- Mount /tmp/.X11-unix/ which is where the current X11 displays are located.
 
Example: 
```bash
docker run -it --rm \
    -e DISPLAY=$DISPLAY \
    -e XAUTHORITY=$XAUTHORITY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v $XAUTHORITY:$XAUTHORITY:ro \
    fast-python-pocl-vgl \
    systemCheck
```

#### Intel OpenCL
If you have an Intel CPU with an integrated GPU (Intel Graphics) you can use the Intel OpenCL platform.
Build with **OPENCL_PLATFORM=intel**, this will install the intel-opencl-icd package:
```bash
docker build . -f runtime.Dockerfile \
    --build-arg OPENCL_PLATFORM=intel \
    --build-arg TYPE=python \
    -t fast-python-intel
```

When running you have to add the following for docker to get access to the Intel Graphics GPU: `--device=/dev/dri`:
```bash
docker run -it --rm --device=/dev/dri fast-python-intel python
```

#### Portable Computing Language (PoCL)

Set **OPENCL_PLATFORM=pocl** (default):
```bash
docker build . -f runtime.Dockerfile \
    --build-arg OPENCL_PLATFORM=pocl \
    --build-arg TYPE=python \
    -t fast-python-pocl
```
To run:
```bash
docker run -it --rm fast-python-pocl python
```

#### NVIDIA OpenCL
To use NVIDIA GPUs in the docker image a different base image from NVIDIA have to be used. 
Build with **BASE_IMAGE=nvidia/cuda:11.0.3-cudnn8-runtime-ubuntu20.04** , this base docker image is provided by NVIDIA and comes with a license, see [https://hub.docker.com/r/nvidia/cuda](https://hub.docker.com/r/nvidia/cuda).
Also set **OPENCL_PLATFORM=nvidia**:
```bash
`docker build . -f runtime.Dockerfile \
    --build-arg BASE_IMAGE=nvidia/cuda:11.0.3-cudnn8-runtime-ubuntu20.04 \
    --build-arg OPENCL_PLATFORM=nvidia \
    --build-arg TYPE=python \
    -t fast-python-nvidia
```
When running you have to set **--gpus all**:
```bash
docker run -it --rm --gpus all fast-python-nvidia python
```

#### Specify FAST version
Set **FAST_VERSION** to specific value:
```bash
docker build . -f runtime.Dockerfile \
    --build-arg FAST_VERSION=4.14.0 \
    --build-arg TYPE=python \
    -t fast-python-intel
```

## FAST Build Docker

This docker container is for building/compiling FAST.
```bash
docker build . -f build.Dockerfile -t fast-build
```
```bash
docker run -it fast-build bash
```

## Apptainer Container Image

The FAST docker images can be converted to an Apptainer container image by first saving it to an OCI file using `docker save`
and then using the `apptainer build` command.

```bash
# Save a FAST docker image to .tar file:
docker save fast-image -o fast-image.tar
# Convert to apptainer sif image format:
sudo apptainer build fast_image.sif docker-archive://fast-image.tar
```

## TODO

- [ ] systemCheck does not work with intel + VGL?
- [ ] xorg support for hardware accelerated rendering
- [ ] For CI testing, we need to autoclose systemCheck somehow
