#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="${1:-iphoneos}"

"$SCRIPT_DIR/build-sdl2.sh" "$PLATFORM"
"$SCRIPT_DIR/build-ogg.sh" "$PLATFORM"
"$SCRIPT_DIR/build-vorbis.sh" "$PLATFORM"
"$SCRIPT_DIR/build-pixman.sh" "$PLATFORM"
"$SCRIPT_DIR/build-theora.sh" "$PLATFORM"
"$SCRIPT_DIR/build-libpng.sh" "$PLATFORM"
"$SCRIPT_DIR/build-freetype.sh" "$PLATFORM"
"$SCRIPT_DIR/build-physfs.sh" "$PLATFORM"
"$SCRIPT_DIR/build-uchardet.sh" "$PLATFORM"
"$SCRIPT_DIR/build-openal.sh" "$PLATFORM"
"$SCRIPT_DIR/build-sdl2-image.sh" "$PLATFORM"
"$SCRIPT_DIR/build-sdl2-ttf.sh" "$PLATFORM"
"$SCRIPT_DIR/build-sdl-sound.sh" "$PLATFORM"
"$SCRIPT_DIR/build-ruby.sh" "$PLATFORM"

echo "==> Built Maou mkxp-z iOS dependency set for $PLATFORM"
