#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

"$SCRIPT_DIR/build-ogg.sh" "$PLATFORM"

run_cmake_dep vorbis "$(require_source vorbis)" \
    -DBUILD_TESTING=OFF
