#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

"$SCRIPT_DIR/build-libpng.sh" "$PLATFORM"

run_cmake_dep freetype "$(require_source freetype)" \
    -DFT_DISABLE_HARFBUZZ=ON \
    -DFT_DISABLE_BROTLI=ON \
    -DFT_DISABLE_BZIP2=ON \
    -DFT_DISABLE_PNG=OFF \
    -DFT_REQUIRE_PNG=OFF
