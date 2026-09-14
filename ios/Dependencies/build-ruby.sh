#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"
configure_platform "${1:-iphoneos}"

RUBY_SOURCE="$(require_source ruby)"
BUILD_DIR="$BUILD_ROOT/ruby-$PLATFORM"

# Ruby's makefiles use VPATH and can accidentally pick up objects left behind
# by the macOS dependency build in the shared source cache.
find "$RUBY_SOURCE" -name '*.o' -delete

case "$PLATFORM" in
    iphoneos)
        RUBY_HOST="arm64-apple-ios"
        RUBY_ARCH_DIR="aarch64-ios"
        RUBY_ARCH_FLAGS="-arch arm64"
        RUBY_MIN_VERSION_FLAG="-mios-version-min=$DEPLOYMENT_TARGET"
        ;;
    iphonesimulator)
        # Simulator dependencies are Apple Silicon only.
        RUBY_HOST="arm64-apple-ios-simulator"
        RUBY_ARCH_DIR="aarch64-ios-simulator"
        RUBY_ARCH_FLAGS="-arch arm64"
        RUBY_MIN_VERSION_FLAG="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
        ;;
esac

SDKROOT="$(xcrun --sdk "$SDK" --show-sdk-path)"
CC="$(xcrun --sdk "$SDK" --find clang)"
AR="$(xcrun --sdk "$SDK" --find ar)"
RANLIB="$(xcrun --sdk "$SDK" --find ranlib)"
mkdir -p "$BUILD_DIR"

export SDKROOT
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig"
export ac_cv_func_getcontext=no
export ac_cv_func_setcontext=no
export ac_cv_func_fdatasync=no
export ac_cv_func_getentropy=no
export ac_cv_func_dup3=no
export ac_cv_func_pipe2=no
export ac_cv_header_sys_vnode_h=no

cd "$BUILD_DIR"

"$RUBY_SOURCE/configure" \
    --prefix="$PREFIX" \
    --host="$RUBY_HOST" \
    --build="$(uname -m)-apple-darwin" \
    --enable-install-static-library \
    --disable-shared \
    --disable-jit-support \
    --with-static-linked-ext \
    --disable-rubygems \
    --disable-install-doc \
    --with-out-ext=fiddle,gdbm,openssl,psych,win32ole,win32 \
    CC="$CC" \
    AR="$AR" \
    RANLIB="$RANLIB" \
    CFLAGS="-std=gnu99 -I$SCRIPT_DIR/include-shims -isysroot $SDKROOT $RUBY_ARCH_FLAGS $RUBY_MIN_VERSION_FLAG -O3" \
    CPPFLAGS="-I$SCRIPT_DIR/include-shims -isysroot $SDKROOT $RUBY_ARCH_FLAGS" \
    LDFLAGS="-isysroot $SDKROOT $RUBY_ARCH_FLAGS $RUBY_MIN_VERSION_FLAG -L$PREFIX/lib" \
    LIBS="-framework CoreFoundation"

mkdir -p enc enc/trans
make -j"$NPROC" miniruby
make -j"$NPROC" libruby-static.a
make -j"$NPROC" libencs enc/encinit.o

RUBY_INCLUDE_DIR="$PREFIX/include/ruby-3.1.0"
mkdir -p "$PREFIX/lib" "$RUBY_INCLUDE_DIR"
# The core archive contains dmyenc.o, which tries to load encoding shared
# libraries that are unavailable in the embedded iOS app. Replace it with
# Ruby's generated static registration and the actual encoding/transcoder
# archives, preserving Ruby's conversion and error semantics.
cp libruby-static.a libruby-embedded-core.a
"$AR" -d libruby-embedded-core.a dmyenc.o
"$(xcrun --sdk "$SDK" --find libtool)" -static \
    -o "$PREFIX/lib/libruby-static.a.tmp" \
    libruby-embedded-core.a enc/encinit.o enc/libenc.a enc/libtrans.a
mv "$PREFIX/lib/libruby-static.a.tmp" "$PREFIX/lib/libruby-static.a"
cp -R "$RUBY_SOURCE/include/"* "$RUBY_INCLUDE_DIR/"
cp -R ".ext/include/$RUBY_ARCH_DIR/"* "$RUBY_INCLUDE_DIR/"

echo "==> Built Ruby for $PLATFORM at $PREFIX"
