#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

export AUTOTOOLS_MAKE_TARGET="-C pixman"
export AUTOTOOLS_INSTALL_TARGET="-C pixman install"

run_autotools_dep pixman "$(require_source pixman)" \
    --disable-dependency-tracking \
    --disable-gtk \
    --disable-libpng \
    --disable-arm-simd \
    --disable-arm-neon \
    --disable-arm-a64-neon \
    --disable-arm-iwmmxt \
    --disable-loongson-mmi \
    --disable-mmx \
    --disable-sse2 \
    --disable-ssse3 \
    --disable-vmx
