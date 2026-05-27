#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

run_cmake_dep ogg "$(require_source ogg)" \
    -DINSTALL_DOCS=OFF \
    -DBUILD_TESTING=OFF
