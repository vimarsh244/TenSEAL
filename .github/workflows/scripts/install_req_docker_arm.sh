#!/bin/sh

set -e

apt update -y
apt install wget curl git build-essential automake libtool libtool-bin clang -y

export CC=clang
export CXX=clang++

# Detect architecture and download appropriate CMake
ARCH=$(uname -m)
CMAKE_VERSION="3.28.0"

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    cmake_install="cmake-${CMAKE_VERSION}-linux-aarch64.sh"
elif [ "$ARCH" = "x86_64" ]; then
    cmake_install="cmake-${CMAKE_VERSION}-linux-x86_64.sh"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Detected architecture: $ARCH"
echo "Downloading CMake: $cmake_install"

wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${cmake_install}
sh ${cmake_install} --skip-license --prefix=/usr/local/ --exclude-subdir

python -m pip install --upgrade pip
pip install -r requirements_dev.txt
pip install setuptools wheel twine auditwheel

cmake --version
