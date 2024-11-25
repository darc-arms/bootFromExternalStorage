#!/bin/bash
# MIT License
# Copyright (c) 2021-23 Jetsonhacks

#
# Run this script on the Jetson after flashing.
# This script installs the additional packages that are on the default SD card image for this JetPack release
#

# First check to see if we're on a Jetson

if [ $(arch) == 'aarch64' ]; then
  if [ ! -f /etc/nv_tegra_release ]; then
    echo 'This script must be run on an NVIDIA Jetson'
    echo 'This machine does not appear to meet that requirement'
    exit
  fi
else
  echo 'This script must be run on an NVIDIA Jetson'
  echo 'This machine does not appear to meet that requirement'
  exit
fi

# Update and install JetPack 36.4 packages
sudo apt update
sudo apt-get install -y \
 nvidia-jetpack \
 python3-vpi2 \  # UPDATED: Updated to `vpi2` for JetPack 36.4
 python3-libnvinfer-dev \
 python3-dev \   # UPDATED: `python3-dev` replaces `python2.7-dev` and `python-dev`
 python3-py \
 python3-attr \
 python3-funcsigs \
 python3-pluggy \
 python3-pytest \
 python3-six \
 uff-converter-tf \
 libtbb-dev \
 libopencv-dev # UPDATED: Added `libopencv-dev` to support OpenCV-related builds

# nvidia-jetpack installs these packages:
# nvidia-cuda
# nvidia-opencv
# nvidia-cudnn8
# nvidia-tensorrt
# nvidia-visionworks
# nvidia-container
# nvidia-vpi2 # UPDATED: Reflects the new VPI version
# nvidia-l4t-jetson-multimedia-api

echo "JetPack 36.4 packages installation completed successfully!"
