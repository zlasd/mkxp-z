#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLATFORM="${1:-iphonesimulator}"
SKIP_DEPS="${2:-}"
DEPLOYMENT_TARGET="${MAOU_IOS_DEPLOYMENT_TARGET:-17.0}"

case "$PLATFORM" in
    iphoneos)
        SDK="iphoneos"
        ARCH_FLAGS=(-arch arm64)
        MIN_VERSION_FLAG="-mios-version-min=$DEPLOYMENT_TARGET"
        ;;
    iphonesimulator)
        SDK="iphonesimulator"
        ARCH_FLAGS=(-arch arm64)
        MIN_VERSION_FLAG="-mios-simulator-version-min=$DEPLOYMENT_TARGET"
        ;;
    *)
        echo "usage: $0 [iphoneos|iphonesimulator] [--skip-deps]" >&2
        exit 2
        ;;
esac

DEPS_DIR="$SCRIPT_DIR/Dependencies/build/$PLATFORM"
DEPENDENCY_STAMP="$DEPS_DIR/.maou-dependency-set.sha256"
DEPENDENCY_SIGNATURE="$({
    printf '%s\n' "$PLATFORM" "$DEPLOYMENT_TARGET"
    xcrun --sdk "$SDK" --show-sdk-path
    xcrun --sdk "$SDK" clang --version
    find "$SCRIPT_DIR/Dependencies" -maxdepth 2 -type f \
        \( -name '*.sh' -o -name '*.patch' \) \
        -exec shasum -a 256 {} + | LC_ALL=C sort
} | shasum -a 256 | awk '{print $1}')"
REQUIRED_DEPENDENCIES=(
    libSDL2.a libSDL2_image.a libSDL2_sound.a libSDL2_ttf.a libfreetype.a
    libogg.a libopenal.a libphysfs.a libpixman-1.a libpng16.a
    libruby-static.a libtheora.a libtheoradec.a libtheoraenc.a libuchardet.a
    libvorbis.a libvorbisenc.a libvorbisfile.a
)
DEPENDENCIES_COMPLETE=1
for dependency in "${REQUIRED_DEPENDENCIES[@]}"; do
    if [ ! -f "$DEPS_DIR/lib/$dependency" ]; then
        DEPENDENCIES_COMPLETE=0
        break
    fi
done

if [ "$SKIP_DEPS" = "--skip-deps" ] || \
   { [ "$DEPENDENCIES_COMPLETE" -eq 1 ] && [ -f "$DEPENDENCY_STAMP" ] \
     && [ "$(cat "$DEPENDENCY_STAMP")" = "$DEPENDENCY_SIGNATURE" ]; }; then
    # The embedding bridge requires our SDL drawable methods. Refresh its
    # independently cached target even while reusing the remaining set.
    "$SCRIPT_DIR/Dependencies/build-sdl2.sh" "$PLATFORM"
else
    "$SCRIPT_DIR/Dependencies/build-all.sh" "$PLATFORM"
    printf '%s\n' "$DEPENDENCY_SIGNATURE" > "$DEPENDENCY_STAMP"
fi

BUILD_DIR="$SCRIPT_DIR/build/$PLATFORM"
OBJ_DIR="$BUILD_DIR/obj"
LIB_DIR="$BUILD_DIR/lib"
LIBRARY="$LIB_DIR/libMaouMkxpZ.a"

if [ ! -f "$DEPS_DIR/lib/libruby-static.a" ]; then
    echo "Ruby static library was not found at $DEPS_DIR/lib/libruby-static.a" >&2
    echo "Run $SCRIPT_DIR/Dependencies/build-all.sh $PLATFORM first." >&2
    exit 1
fi

# Old --skip-deps caches contain Ruby's dynamic encoding loader without any
# loadable enc/*.so. Refresh Ruby when the static conversion tables are absent.
RUBY_SYMBOLS_FILE="$DEPS_DIR/ruby-encoding-symbols"
nm -gU "$DEPS_DIR/lib/libruby-static.a" > "$RUBY_SYMBOLS_FILE"
if ! grep -q ' T _Init_trans_japanese$' "$RUBY_SYMBOLS_FILE" || \
   ! grep -q ' T _Init_trans_utf_16_32$' "$RUBY_SYMBOLS_FILE"; then
    "$SCRIPT_DIR/Dependencies/build-ruby.sh" "$PLATFORM"
fi

SDKROOT="$(xcrun --sdk "$SDK" --show-sdk-path)"
CC="$(xcrun --sdk "$SDK" --find clang)"
CXX="$(xcrun --sdk "$SDK" --find clang++)"
LIBTOOL="$(xcrun --sdk "$SDK" --find libtool)"
NPROC="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
GIT_HASH="$(git -C "$REPO_DIR" rev-parse --short HEAD)"

mkdir -p "$OBJ_DIR" "$LIB_DIR"

common_args=(
    -isysroot "$SDKROOT"
    "${ARCH_FLAGS[@]}"
    "$MIN_VERSION_FLAG"
    -O2
    -fvisibility=hidden
    -fobjc-arc
    -fdeclspec
    -DMAOU_MKXPZ_EMBEDDED_ONLY
    -DMAOU_MKXPZ_LINKED_ZLIB_EXTENSION
    -DMKXPZ_BUILD_XCODE
    -DMKXPZ_VERSION=\"2.4.2\"
    -DMKXPZ_GIT_HASH=\"$GIT_HASH\"
    -DHAVE_NANOSLEEP
    -DWORKDIR_CURRENT
    -DGLES2_HEADER
    -DMKXPZ_INIT_GL_LATER
    -DAL_LIBTYPE_STATIC
    -DMKXPZ_ALCDEVICE=ALCdevice
    -I"$REPO_DIR"
    -I"$REPO_DIR/src"
    -I"$REPO_DIR/src/audio"
    -I"$REPO_DIR/src/crypto"
    -I"$REPO_DIR/src/display"
    -I"$REPO_DIR/src/display/gl"
    -I"$REPO_DIR/src/display/libnsgif"
    -I"$REPO_DIR/src/display/libnsgif/utils"
    -I"$REPO_DIR/src/etc"
    -I"$REPO_DIR/src/filesystem"
    -I"$REPO_DIR/src/filesystem/ghc"
    -I"$REPO_DIR/src/input"
    -I"$REPO_DIR/src/net"
    -I"$REPO_DIR/src/system"
    -I"$REPO_DIR/src/util"
    -I"$REPO_DIR/src/util/sigslot"
    -I"$REPO_DIR/src/util/sigslot/adapter"
    -I"$REPO_DIR/binding"
    -I"$DEPS_DIR/include"
    -I"$DEPS_DIR/include/AL"
    -I"$DEPS_DIR/include/SDL2"
    -I"$DEPS_DIR/include/freetype2"
    -I"$DEPS_DIR/include/pixman-1"
    -I"$DEPS_DIR/include/ruby-3.1.0"
    -I"$DEPS_DIR/include/uchardet"
)

cpp_sources=(
    src/main.cpp
    src/config.cpp
    src/eventthread.cpp
    src/settingsmenu.cpp
    src/sharedstate.cpp
    src/audio/alstream.cpp
    src/audio/audio.cpp
    src/audio/audiostream.cpp
    src/audio/fluid-fun.cpp
    src/audio/midisource.cpp
    src/audio/sdlsoundsource.cpp
    src/audio/soundemitter.cpp
    src/audio/vorbissource.cpp
    src/crypto/rgssad.cpp
    src/display/autotiles.cpp
    src/display/autotilesvx.cpp
    src/display/bitmap.cpp
    src/display/font.cpp
    src/display/graphics.cpp
    src/display/plane.cpp
    src/display/sprite.cpp
    src/display/tilemap.cpp
    src/display/tilemapvx.cpp
    src/display/viewport.cpp
    src/display/window.cpp
    src/display/windowvx.cpp
    src/display/gl/gl-debug.cpp
    src/display/gl/gl-fun.cpp
    src/display/gl/gl-meta.cpp
    src/display/gl/glstate.cpp
    src/display/gl/scene.cpp
    src/display/gl/shader.cpp
    src/display/gl/texpool.cpp
    src/display/gl/tileatlas.cpp
    src/display/gl/tileatlasvx.cpp
    src/display/gl/tilequad.cpp
    src/display/gl/vertex.cpp
    src/util/iniconfig.cpp
    src/util/win-consoleutils.cpp
    src/etc/etc.cpp
    src/etc/table.cpp
    src/filesystem/filesystem.cpp
    src/input/input.cpp
    src/input/keybindings.cpp
    src/net/LUrlParser.cpp
    src/net/net.cpp
    binding/binding-mri.cpp
    binding/binding-util.cpp
    binding/table-binding.cpp
    binding/etc-binding.cpp
    binding/bitmap-binding.cpp
    binding/font-binding.cpp
    binding/graphics-binding.cpp
    binding/input-binding.cpp
    binding/sprite-binding.cpp
    binding/viewport-binding.cpp
    binding/plane-binding.cpp
    binding/window-binding.cpp
    binding/tilemap-binding.cpp
    binding/audio-binding.cpp
    binding/module_rpg.cpp
    binding/filesystem-binding.cpp
    binding/windowvx-binding.cpp
    binding/tilemapvx-binding.cpp
    binding/http-binding.cpp
)

c_sources=(
    src/theoraplay/theoraplay.c
    src/display/libnsgif/libnsgif.c
    src/display/libnsgif/lzw.c
    macos/Dependencies/downloads/aarch64-apple-darwin/ruby/ext/zlib/zlib.c
)

objcxx_sources=(
    src/filesystem/filesystemImplApple.mm
    src/system/systemImplApple.mm
)

objects=()
objects_changed=0

# The embedded runtime shares layouts across translation units. Source-only
# timestamps can silently link incompatible objects after a header change.
compile_signature="$(python3 - "$REPO_DIR" "$CXX" "${common_args[@]}" <<'PY'
import hashlib, pathlib, sys
root=pathlib.Path(sys.argv[1]); h=hashlib.sha256()
h.update(repr(sys.argv[2:]).encode())
files=[root/'ios/build-runtime.sh']
for folder in ('src','binding'):
    files += [p for p in (root/folder).rglob('*') if p.suffix in ('.h','.hpp','.xxd')]
for p in sorted(files):h.update(str(p.relative_to(root)).encode());h.update(p.read_bytes())
print(h.hexdigest())
PY
)"
previous_signature="$(cat "$OBJ_DIR/compile-signature" 2>/dev/null || true)"

compile_source() {
    local compiler="$1"
    local source="$2"
    shift 2

    local input="$REPO_DIR/$source"
    local object="$OBJ_DIR/${source//\//_}.o"
    objects+=("$object")

    if [ "$compile_signature" = "$previous_signature" ] && [ -f "$object" ] && [ "$object" -nt "$input" ]; then
        return
    fi

    echo "==> Compiling $source"
    "$compiler" "${common_args[@]}" "$@" -c "$input" -o "$object"
    objects_changed=1
}

for source in "${cpp_sources[@]}"; do
    compile_source "$CXX" "$source" -std=gnu++14 -Wno-deprecated-declarations -Wno-unknown-pragmas
done

for source in "${c_sources[@]}"; do
    compile_source "$CC" "$source" -std=gnu99
done

for source in "${objcxx_sources[@]}"; do
    compile_source "$CXX" "$source" -std=gnu++14 -x objective-c++ -Wno-deprecated-declarations
done

if [ "$objects_changed" -eq 1 ] || [ ! -f "$LIBRARY" ]; then
    echo "==> Archiving $LIBRARY"
    "$LIBTOOL" -static -o "$LIBRARY" "${objects[@]}"
else
    echo "==> mkxp-z iOS runtime objects are unchanged"
fi
printf '%s\n' "$compile_signature" > "$OBJ_DIR/compile-signature"

SYMBOLS_FILE="$BUILD_DIR/libMaouMkxpZ.symbols"
nm -gU "$LIBRARY" > "$SYMBOLS_FILE"
if ! grep -q "_maou_mkxpz_run" "$SYMBOLS_FILE"; then
    echo "libMaouMkxpZ.a did not export maou_mkxpz_run" >&2
    exit 1
fi

echo "==> Built mkxp-z iOS runtime library for $PLATFORM at $LIBRARY"
