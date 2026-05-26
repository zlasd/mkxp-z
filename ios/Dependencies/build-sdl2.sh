#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDL2_SOURCE="$REPO_DIR/macos/Dependencies/downloads/aarch64-apple-darwin/sdl2"
PLATFORM="${1:-iphoneos}"

case "$PLATFORM" in
    iphoneos)
        SDK="iphoneos"
        ARCHS="arm64"
        ;;
    iphonesimulator)
        SDK="iphonesimulator"
        ARCHS="arm64;x86_64"
        ;;
    *)
        echo "usage: $0 [iphoneos|iphonesimulator]" >&2
        exit 2
        ;;
esac

if [ ! -f "$SDL2_SOURCE/CMakeLists.txt" ]; then
    echo "SDL2 source checkout was not found at $SDL2_SOURCE" >&2
    echo "Run the pinned dependency fetch step before building iOS SDL2." >&2
    exit 1
fi

NPROC="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
PREFIX="$SCRIPT_DIR/build/$PLATFORM"
BUILD_DIR="$SCRIPT_DIR/build/sdl2-$PLATFORM"

cmake \
    -S "$SDL2_SOURCE" \
    -B "$BUILD_DIR" \
    -G "Unix Makefiles" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SDK" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_C_FLAGS="-DGLES_SILENCE_DEPRECATION" \
    -DBUILD_SHARED_LIBS=OFF \
    -DSDL_STATIC=ON \
    -DSDL_SHARED=OFF \
    -DSDL_TEST=OFF

cmake --build "$BUILD_DIR" --target install -j"$NPROC"

echo "==> Built SDL2 for $PLATFORM at $PREFIX"
