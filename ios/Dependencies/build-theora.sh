#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

run_autotools_dep theora "$(require_source theora)" \
    --disable-dependency-tracking \
    --disable-examples \
    --disable-oggtest \
    --disable-vorbistest \
    --disable-asm
