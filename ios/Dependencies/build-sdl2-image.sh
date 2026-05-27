#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

"$SCRIPT_DIR/build-sdl2.sh" "$PLATFORM"

run_cmake_dep sdl2_image "$(require_source sdl2_image)" \
    -DSDL2IMAGE_INSTALL=ON \
    -DSDL2IMAGE_SAMPLES=OFF \
    -DSDL2IMAGE_TESTS=OFF \
    -DSDL2IMAGE_DEPS_SHARED=OFF \
    -DSDL2IMAGE_VENDORED=ON \
    -DSDL2IMAGE_BACKEND_STB=ON \
    -DSDL2IMAGE_BACKEND_IMAGEIO=OFF \
    -DSDL2IMAGE_AVIF=OFF \
    -DSDL2IMAGE_JXL=OFF \
    -DSDL2IMAGE_TIF=OFF \
    -DSDL2IMAGE_WEBP=OFF \
    -DSDL2IMAGE_PNG_SHARED=OFF \
    -DSDL2IMAGE_JPG_SHARED=OFF
