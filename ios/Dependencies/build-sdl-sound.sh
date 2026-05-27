#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

"$SCRIPT_DIR/build-sdl2.sh" "$PLATFORM"
"$SCRIPT_DIR/build-vorbis.sh" "$PLATFORM"

run_cmake_dep sdl_sound "$(require_source sdl_sound)" \
    -DSDLSOUND_BUILD_SHARED=OFF \
    -DSDLSOUND_BUILD_TEST=OFF \
    -DSDLSOUND_DECODER_COREAUDIO=OFF
