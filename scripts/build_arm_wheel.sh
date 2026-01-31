#!/bin/bash
#
# Build TenSEAL wheel natively on ARM64 devices
# Supported: Jetson Orin NX, Raspberry Pi 4/5, other ARM64 Linux
#
# Usage:
#   ./scripts/build_arm_wheel.sh
#   ./scripts/build_arm_wheel.sh --python python3.11
#   ./scripts/build_arm_wheel.sh --output-dir /path/to/wheels
#

set -e

# Default values
PYTHON_CMD="${PYTHON_CMD:-python3}"
OUTPUT_DIR="${OUTPUT_DIR:-./wheelhouse}"
BUILD_DIR="${BUILD_DIR:-./build}"
CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
JOBS="${JOBS:-$(nproc)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --python)
            PYTHON_CMD="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --jobs|-j)
            JOBS="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --python PYTHON    Python executable to use (default: python3)"
            echo "  --output-dir DIR   Output directory for wheels (default: ./wheelhouse)"
            echo "  --build-dir DIR    Build directory (default: ./build)"
            echo "  --jobs N           Number of parallel jobs (default: nproc)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check architecture
ARCH=$(uname -m)
print_info "Detected architecture: $ARCH"

if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
    print_warn "This script is optimized for ARM64. Detected: $ARCH"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Python
print_info "Using Python: $($PYTHON_CMD --version)"
PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
print_info "Python version: $PYTHON_VERSION"

# Check for required tools
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is required but not installed"
        return 1
    fi
    return 0
}

print_info "Checking required tools..."
MISSING_TOOLS=0
for tool in cmake git clang clang++; do
    if ! check_command $tool; then
        MISSING_TOOLS=1
    fi
done

if [[ $MISSING_TOOLS -eq 1 ]]; then
    print_error "Missing required tools. Install them with:"
    echo ""
    echo "  # Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install -y build-essential cmake git clang automake libtool"
    echo ""
    echo "  # For Jetson (JetPack 5+):"
    echo "  sudo apt update"
    echo "  sudo apt install -y build-essential cmake git clang automake libtool python3-dev"
    echo ""
    exit 1
fi

# Check CMake version
CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
print_info "CMake version: $CMAKE_VERSION"

# Set compiler environment
export CC=clang
export CXX=clang++
print_info "Using compiler: CC=$CC, CXX=$CXX"

# Create output directory
mkdir -p "$OUTPUT_DIR"
print_info "Output directory: $OUTPUT_DIR"

# Install/upgrade build dependencies
print_info "Installing Python build dependencies..."
$PYTHON_CMD -m pip install --upgrade pip setuptools wheel build

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

print_info "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Build the wheel
print_info "Building TenSEAL wheel..."
print_info "This may take a while (15-30 minutes on Jetson/RPi)..."

# Set parallel jobs for CMake
export CMAKE_BUILD_PARALLEL_LEVEL=$JOBS
print_info "Using $JOBS parallel jobs"

# Build using pip wheel
$PYTHON_CMD -m pip wheel . \
    --no-deps \
    --wheel-dir "$OUTPUT_DIR" \
    -v

# List built wheels
print_info "Built wheels:"
ls -la "$OUTPUT_DIR"/*.whl 2>/dev/null || print_error "No wheels found!"

# Verify the wheel
WHEEL_FILE=$(ls "$OUTPUT_DIR"/*.whl 2>/dev/null | head -1)
if [[ -n "$WHEEL_FILE" ]]; then
    print_info "Testing wheel installation..."
    
    # Create a temporary virtual environment for testing
    TEST_VENV=$(mktemp -d)
    $PYTHON_CMD -m venv "$TEST_VENV"
    source "$TEST_VENV/bin/activate"
    
    pip install "$WHEEL_FILE"
    
    # Quick test
    python -c "import tenseal; print(f'TenSEAL version: {tenseal.__version__}')" && \
        print_info "Wheel test passed!" || \
        print_error "Wheel test failed!"
    
    deactivate
    rm -rf "$TEST_VENV"
    
    print_info ""
    print_info "=========================================="
    print_info "Build complete!"
    print_info "Wheel: $WHEEL_FILE"
    print_info ""
    print_info "To install:"
    print_info "  pip install $WHEEL_FILE"
    print_info "=========================================="
else
    print_error "Build failed - no wheel produced"
    exit 1
fi
