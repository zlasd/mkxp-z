#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

run_cmake_dep physfs "$(require_source physfs)" \
    -DPHYSFS_BUILD_STATIC=ON \
    -DPHYSFS_BUILD_SHARED=OFF \
    -DPHYSFS_BUILD_TEST=OFF \
    -DPHYSFS_BUILD_DOCS=OFF
