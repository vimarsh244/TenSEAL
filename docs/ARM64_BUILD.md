# TenSEAL ARM64 Build Guide

Build and install TenSEAL on ARM64 devices including NVIDIA Jetson (Orin NX, AGX Orin, Xavier), Raspberry Pi 4/5, and other ARM64 Linux systems.


```bash
pip install tenseal-*-cp311-cp311-manylinux_2_28_aarch64.whl
```


#### Build Options

```bash
# Use specific Python version
./scripts/build_arm_wheel.sh --python python3.11

# Custom output directory
./scripts/build_arm_wheel.sh --output-dir ~/my-wheels

```

### Manual Build

```bash
# Set up environment
export CC=clang
export CXX=clang++

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install build dependencies
pip install --upgrade pip setuptools wheel

# Build and install
pip install .

# Or build wheel only
pip wheel . --no-deps --wheel-dir wheelhouse
```

### Changes to do for python 3.13+ building

In cmake/xtensor.cmake change to following

```
include(FetchContent)

add_definitions(-DXTENSOR_USE_XSIMD)
set(XTENSOR_USE_XSIMD ON)
set(JSON_BuildTests OFF)
set(JSON_Install OFF)

FetchContent_Declare(
  com_nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json
  GIT_TAG        v3.9.1
)
FetchContent_Declare(
  com_xtensorstack_xtl
  GIT_REPOSITORY https://github.com/xtensor-stack/xtl
  GIT_TAG        0.8.0
)
FetchContent_Declare(
  com_xtensorstack_xsimd
  GIT_REPOSITORY https://github.com/xtensor-stack/xsimd
  GIT_TAG        13.2.0
)
FetchContent_Declare(
  com_xtensorstack_xtensor
  GIT_REPOSITORY https://github.com/xtensor-stack/xtensor
  GIT_TAG        0.26.0
)
FetchContent_MakeAvailable(com_nlohmann_json com_xtensorstack_xtl com_xtensorstack_xsimd com_xtensorstack_xtensor)

include_directories(${com_nlohmann_json_SOURCE_DIR}/include/)
include_directories(${com_xtensorstack_xtl_SOURCE_DIR}/include)
include_directories(${com_xtensorstack_xsimd_SOURCE_DIR}/include)
include_directories(${com_xtensorstack_xtensor_SOURCE_DIR}/include)

```


In tenseal/cpp/tensors/tensor_storage.h
change imports parts as follows:
```

#include "gsl/span"
#include "tenseal/cpp/utils/helpers.h"
#include "xtensor/containers/xadapt.hpp"
#include "xtensor/containers/xarray.hpp"
#include "xtensor/io/xio.hpp"
#include "xtensor/io/xjson.hpp"
#include "xtensor/views/xstrided_view.hpp"
#include "xtensor/views/xview.hpp"

```