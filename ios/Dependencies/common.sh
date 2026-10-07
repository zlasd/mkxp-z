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
            ARCHS="arm64"
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

cmake_cache_matches_paths() {
    local build_dir="$1"
    local source="$2"
    local cache="$build_dir/CMakeCache.txt"

    [ -f "$cache" ] || return 1
    [ "$(sed -n 's/^CMAKE_CACHEFILE_DIR:[^=]*=//p' "$cache" | tail -n 1)" = "$build_dir" ] || return 1
    [ "$(sed -n 's/^CMAKE_HOME_DIRECTORY:[^=]*=//p' "$cache" | tail -n 1)" = "$source" ]
}

# Autotools' `autoreconf -isf` installs auxiliary files as symlinks on macOS.
# The shared macOS dependency checkout can therefore retain links into a
# versioned Homebrew Cellar which no longer exists when an iOS archive is
# built.  Prepare a source snapshot from the pinned Git checkout and regenerate
# the build system with copies whenever the source contains missing or linked
# auxiliary files.  Keep the generated snapshot under the ignored iOS build
# directory so the source cache remains reusable and portable between hosts.
AUTOTOOLS_AUXILIARY_FILES=(
    ltmain.sh compile missing install-sh depcomp
    config.guess config.sub configure aclocal.m4
)
AUTOTOOLS_MACRO_FILES=(
    m4/libtool.m4 m4/ltoptions.m4 m4/ltsugar.m4
    m4/ltversion.m4 m4/lt~obsolete.m4
)

autotools_source_complete() {
    local root="$1"
    local macro_stamp="$2"
    local file

    for file in "${AUTOTOOLS_AUXILIARY_FILES[@]}"; do
        if [ ! -f "$root/$file" ] || [ -L "$root/$file" ]; then
            return 1
        fi
    done
    if [ -f "$macro_stamp" ]; then
        while IFS= read -r file; do
            [ -n "$file" ] || continue
            if [ ! -f "$root/$file" ] || [ -L "$root/$file" ]; then
                return 1
            fi
        done < "$macro_stamp"
    fi
    return 0
}

prepare_autotools_source() {
    local name="$1"
    local source="$2"
    local prepared_source="$BUILD_ROOT/sources/$name"
    local stamp="$prepared_source/.maou-autotools-source"
    local macro_stamp="$prepared_source/.maou-autotools-macros"
    local source_revision=""
    local file
    local needs_prepare=0
    local prepared_complete=1

    if source_revision="$(git -C "$source" rev-parse --verify HEAD 2>/dev/null)"; then
        if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$source_revision" ]; then
            if [ ! -f "$macro_stamp" ]; then
                prepared_complete=0
            fi
            if [ "$prepared_complete" -eq 1 ] && \
               autotools_source_complete "$prepared_source" "$macro_stamp"; then
                printf '%s\n' "$prepared_source"
                return 0
            fi
        fi
    fi

    for file in "${AUTOTOOLS_AUXILIARY_FILES[@]}"; do
        if [ ! -f "$source/$file" ] || [ -L "$source/$file" ]; then
            needs_prepare=1
            break
        fi
    done
    if [ "$needs_prepare" -eq 0 ]; then
        for file in "${AUTOTOOLS_MACRO_FILES[@]}"; do
            if [ -L "$source/$file" ]; then
                needs_prepare=1
                break
            fi
        done
    fi
    if [ "$needs_prepare" -eq 0 ]; then
        printf '%s\n' "$source"
        return 0
    fi

    if [ -z "$source_revision" ]; then
        echo "Autotools source $source has missing or linked auxiliary files but is not a Git checkout." >&2
        echo "Refetch the pinned dependency source before building iOS dependencies." >&2
        return 1
    fi
    if [ -n "$(git -C "$source" status --porcelain --untracked-files=no)" ]; then
        echo "Autotools source $source has tracked changes; refusing to regenerate it." >&2
        return 1
    fi

    if [ -e "$prepared_source" ]; then
        rm -rf "$prepared_source"
    fi
    mkdir -p "$prepared_source"
    : > "$macro_stamp"
    for file in "${AUTOTOOLS_MACRO_FILES[@]}"; do
        if [ -e "$source/$file" ] || [ -L "$source/$file" ]; then
            printf '%s\n' "$file" >> "$macro_stamp"
        fi
    done
    if ! git -C "$source" archive --format=tar "$source_revision" | tar -xf - -C "$prepared_source"; then
        echo "failed to archive Autotools source for $name" >&2
        return 1
    fi
    if ! autoreconf -if "$prepared_source" >&2; then
        echo "autoreconf failed for $name" >&2
        return 1
    fi

    if ! autotools_source_complete "$prepared_source" "$macro_stamp"; then
        echo "autoreconf produced incomplete auxiliary files for $name" >&2
        return 1
    fi
    printf '%s\n' "$source_revision" > "$stamp"
    echo "==> Prepared portable Autotools source for $name at $prepared_source" >&2
    printf '%s\n' "$prepared_source"
}

run_cmake_dep() {
    local name="$1"
    local source="$2"
    shift 2

    local build_dir="$BUILD_ROOT/$name-$PLATFORM"
    local toolchain_stamp="$build_dir/.maou-toolchain"
    local toolchain
    # CMakeCache.txt records absolute source, build, and install paths. Include
    # those paths in the stamp so a copied cache cannot survive a worktree move
    # merely because the SDK and compiler are unchanged.
    toolchain="$(printf '%s\n' "$source" "$build_dir" "$PREFIX" "$DEPLOYMENT_TARGET"
xcrun --sdk "$SDK" --show-sdk-path
xcrun --sdk "$SDK" clang --version)"
    local fresh_args=()
    if [ -f "$build_dir/CMakeCache.txt" ] && \
       { [ ! -f "$toolchain_stamp" ] || [ "$(cat "$toolchain_stamp")" != "$toolchain" ]; }; then
        # Find-package caches embed absolute SDK paths (for example ZLIB).
        # Reconfigure only this dependency after an Xcode/SDK upgrade; retain
        # source downloads, installed dependencies and incremental object files.
        fresh_args=(--fresh)
    fi

    cmake \
        ${fresh_args[@]+"${fresh_args[@]}"} \
        -U CMAKE_APPLE_ARCH_SYSROOTS \
        -U CMAKE_OSX_ARCHITECTURES \
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
    printf '%s\n' "$toolchain" > "$toolchain_stamp"
    echo "==> Built $name for $PLATFORM at $PREFIX"
}

run_autotools_dep() {
    local name="$1"
    local source="$2"
    shift 2

    source="$(prepare_autotools_source "$name" "$source")"

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
