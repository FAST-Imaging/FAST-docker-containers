#!/bin/bash
# Clone and build FAST
git clone https://github.com/FAST-Imaging/FAST.git
cd FAST
cmake -B build \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DFAST_MODULE_OpenVINO=ON \
    -DFAST_MODULE_Dicom=ON \
    -DFAST_MODULE_WholeSlideImaging=ON \
    -DFAST_MODULE_OpenIGTLink=ON \
    -DFAST_MODULE_Clarius=ON \
    -DFAST_MODULE_TensorFlow=ON \
    -DFAST_MODULE_HDF5=ON \
    -DFAST_MODULE_Plotting=ON \
    -DFAST_MODULE_Python=ON \
    -DFAST_MODULE_RealSense=ON \
    -DFAST_BUILD_EXAMPLES=ON

# Build FAST
cmake --build build --config $BUILD_TYPE -j8

# Build pyfast python wheel
cmake --build build --config $BUILD_TYPE --target python-wheel -j8