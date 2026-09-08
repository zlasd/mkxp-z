#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

CONTROLLER_SUPPORT="${MAOU_CONTROLLER_SUPPORT:-NO}"
case "$CONTROLLER_SUPPORT" in
    1|YES|yes|TRUE|true) CONTROLLER_SUPPORT=ON ;;
    0|NO|no|FALSE|false) CONTROLLER_SUPPORT=OFF ;;
    *) echo "MAOU_CONTROLLER_SUPPORT must be YES or NO" >&2; exit 2 ;;
esac

SDL_SOURCE="$(require_source sdl2)"
SDL_BUILD_NAME="sdl2-controller-enabled"
SDL_C_FLAGS="-DGLES_SILENCE_DEPRECATION -DMAOU_CONTROLLER_SUPPORT=1"

# Apply the embedded drawable fix in both controller configurations. Include
# every patch in the stamp so cached source trees cannot silently omit a fix.
PATCH_FILES=("$SCRIPT_DIR/patches/sdl2-embedded-drawable.patch")
if [ "$CONTROLLER_SUPPORT" = "OFF" ]; then
    PATCH_FILES+=("$SCRIPT_DIR/patches/sdl2-disable-gamecontroller.patch")
    SDL_BUILD_NAME="sdl2-controller-free"
    SDL_C_FLAGS="-DGLES_SILENCE_DEPRECATION -DMAOU_CONTROLLER_SUPPORT=0"
fi
PATCH_HASH="$(shasum -a 256 "${PATCH_FILES[@]}" | shasum -a 256 | awk '{print $1}')"
PATCHED_SOURCE="$BUILD_ROOT/sources/$SDL_BUILD_NAME"
PATCH_STAMP="$PATCHED_SOURCE/.maou-patches"
if [ ! -f "$PATCH_STAMP" ] || [ "$(cat "$PATCH_STAMP")" != "$PATCH_HASH" ]; then
    rm -rf "$PATCHED_SOURCE"
    mkdir -p "$PATCHED_SOURCE"
    ditto "$SDL_SOURCE" "$PATCHED_SOURCE"
    for patch_file in "${PATCH_FILES[@]}"; do
        patch -d "$PATCHED_SOURCE" -p1 < "$patch_file"
    done
    printf '%s\n' "$PATCH_HASH" > "$PATCH_STAMP"
fi
SDL_SOURCE="$PATCHED_SOURCE"

run_cmake_dep "$SDL_BUILD_NAME" "$SDL_SOURCE" \
    -DCMAKE_C_FLAGS="$SDL_C_FLAGS" \
    -DSDL_STATIC=ON \
    -DSDL_SHARED=OFF \
    -DSDL_TEST=OFF \
    -DSDL_JOYSTICK="$CONTROLLER_SUPPORT" \
    -DSDL_HAPTIC="$CONTROLLER_SUPPORT" \
    -DSDL_HIDAPI="$CONTROLLER_SUPPORT" \
    -DSDL_HIDAPI_JOYSTICK="$CONTROLLER_SUPPORT" \
    -DSDL_VIRTUAL_JOYSTICK="$CONTROLLER_SUPPORT"
