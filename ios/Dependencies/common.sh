#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_ROOT="$REPO_DIR/macos/Dependencies/downloads/aarch64-apple-darwin"
BUILD_ROOT="$SCRIPT_DIR/build"
DEPLOYMENT_TARGET="${MAOU_IOS_DEPLOYMENT_TARGET:-17.0}"
NPROC="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

configure_platform() {
    PLATFORM="${1:-iphoneos}"

    case "$PLATFORM" in
        iphoneos)
            SDK="iphoneos"
            ARCHS="arm64"
            IOS_HOST="arm-apple-darwin"
            ;;
        iphonesimulator)
            SDK="iphonesimulator"
            ARCHS="arm64;x86_64"
            IOS_HOST="arm-apple-darwin"
            ;;
        *)
            echo "usage: $0 [iphoneos|iphonesimulator]" >&2
            exit 2
            ;;
    esac

    PREFIX="$BUILD_ROOT/$PLATFORM"
    mkdir -p "$PREFIX"

    export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
    export PKG_CONFIG_PATH="$PKG_CONFIG_LIBDIR"
    export CMAKE_PREFIX_PATH="$PREFIX"
}

require_source() {
    local name="$1"
    local path="$SOURCE_ROOT/$name"

    if [ ! -d "$path" ]; then
        echo "$name source checkout was not found at $path" >&2
        echo "Run the pinned dependency fetch step before building iOS dependencies." >&2
        exit 1
    fi

    printf '%s\n' "$path"
}

run_cmake_dep() {
    local name="$1"
    local source="$2"
    shift 2

    local build_dir="$BUILD_ROOT/$name-$PLATFORM"

    cmake \
        -S "$source" \
        -B "$build_dir" \
        -G "Unix Makefiles" \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_SYSROOT="$SDK" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
        -DCMAKE_INSTALL_PREFIX="$PREFIX" \
        -DCMAKE_PREFIX_PATH="$PREFIX" \
        -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_FLAGS="-DGLES_SILENCE_DEPRECATION" \
        -DCMAKE_CXX_FLAGS="-DGLES_SILENCE_DEPRECATION" \
        -DBUILD_SHARED_LIBS=OFF \
        "$@"

    cmake --build "$build_dir" --target install -j"$NPROC"
    echo "==> Built $name for $PLATFORM at $PREFIX"
}

run_autotools_dep() {
    local name="$1"
    local source="$2"
    shift 2

    local build_dir="$BUILD_ROOT/$name-$PLATFORM"
    local sdkroot
    local cc
    local ar
    local ranlib
    local min_version_flag
    local arch_flags

    sdkroot="$(xcrun --sdk "$SDK" --show-sdk-path)"
    cc="$(xcrun --sdk "$SDK" --find clang)"
    ar="$(xcrun --sdk "$SDK" --find ar)"
    ranlib="$(xcrun --sdk "$SDK" --find ranlib)"

    case "$PLATFORM" in
        iphoneos)
            arch_flags="-arch arm64"
            min_version_flag="-mios-version-min=$DEPLOYMENT_TARGET"
            ;;
        iphonesimulator)
            arch_flags="-arch arm64"
            min_version_flag="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
            ;;
    esac

    mkdir -p "$build_dir"
    if [ -f "$build_dir/Makefile" ]; then
        make -C "$build_dir" distclean >/dev/null 2>&1 || true
    fi
    if [ -f "$source/config.status" ]; then
        make -C "$source" distclean >/dev/null 2>&1 || true
    fi
    cd "$build_dir"

    CC="$cc" \
    AR="$ar" \
    RANLIB="$ranlib" \
    CFLAGS="-isysroot $sdkroot $arch_flags $min_version_flag -O3 -I$PREFIX/include" \
    CPPFLAGS="-isysroot $sdkroot $arch_flags -I$PREFIX/include" \
    LDFLAGS="-isysroot $sdkroot $arch_flags $min_version_flag -L$PREFIX/lib" \
    PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig" \
    "$source/configure" \
        --host="$IOS_HOST" \
        --prefix="$PREFIX" \
        --disable-shared \
        --enable-static \
        "$@"

    if [ -n "${AUTOTOOLS_MAKE_TARGET:-}" ]; then
        make -j"$NPROC" $AUTOTOOLS_MAKE_TARGET
    else
        make -j"$NPROC"
    fi

    if [ -n "${AUTOTOOLS_INSTALL_TARGET:-}" ]; then
        make $AUTOTOOLS_INSTALL_TARGET
    else
        make install
    fi
    echo "==> Built $name for $PLATFORM at $PREFIX"
}
