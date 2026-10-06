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

# CMake's install target rewrites libSDL2.a even when no object changed. That
# new timestamp makes the application relink on every Xcode invocation, so
# bypass the dependency build when the exact source/toolchain configuration is
# already installed. One active stamp is shared by both controller modes to
# prevent switching modes from reusing the other mode's library.
SDL_CACHE_STAMP="$PREFIX/.maou-sdl2-active.sha256"
SDL_CACHE_KEY="$({
    printf '%s\n' "$PLATFORM" "$DEPLOYMENT_TARGET" "$CONTROLLER_SUPPORT" \
        "$SDL_C_FLAGS" "$PATCH_HASH" "$SDL_SOURCE" "$BUILD_ROOT/$SDL_BUILD_NAME-$PLATFORM" "$PREFIX"
    git -C "$REPO_DIR" rev-parse HEAD
    xcrun --sdk "$SDK" --show-sdk-path
    xcrun --sdk "$SDK" clang --version
    shasum -a 256 "$0" "$SCRIPT_DIR/common.sh" "${PATCH_FILES[@]}"
} | shasum -a 256 | awk '{print $1}')"
if [ -f "$PREFIX/lib/libSDL2.a" ] \
    && [ -f "$PREFIX/include/SDL2/SDL.h" ] \
    && [ -f "$SDL_CACHE_STAMP" ] \
    && [ "$(cat "$SDL_CACHE_STAMP")" = "$SDL_CACHE_KEY" ]; then
    echo "==> Reusing unchanged SDL2 for $PLATFORM at $PREFIX"
    exit 0
fi

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
printf '%s\n' "$SDL_CACHE_KEY" > "$SDL_CACHE_STAMP"
