#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

"$SCRIPT_DIR/build-sdl2.sh" "$PLATFORM"
"$SCRIPT_DIR/build-freetype.sh" "$PLATFORM"

run_cmake_dep sdl2_ttf "$(require_source sdl2_ttf)" \
    -DTTF_WITH_HARFBUZZ=OFF
