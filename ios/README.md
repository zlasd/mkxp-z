# Maou iOS Runtime Notes

Maou embeds mkxp-z on iOS through the exported C bridge in
`src/maou_mkxpz.h`:

- `maou_mkxpz_run`
- `maou_mkxpz_request_stop`
- `maou_mkxpz_send_key`
- `maou_mkxpz_resize`

The app side discovers these symbols from the main executable at runtime, so the
iOS build must link the mkxp-z object/library into the Maou app binary and keep
the symbols exported.

The Apple platform source files now have UIKit branches for iOS. The remaining
work for a complete iOS runtime target is to build and link mkxp-z plus its
native dependencies for `iphoneos` and `iphonesimulator`:

- SDL2, SDL2_image, SDL2_ttf, SDL2_sound
- Ruby
- OpenAL
- PhysFS
- FreeType, pixman, libpng, zlib
- ogg, vorbis, theora
- uchardet, bzip2, iconv

Runtime support assets, such as `Assets.bundle`, `Preload`, `Ruby`, and shader
files, should be copied into Maou at:

`Packages/MaouCore/Sources/Resources/MKXPZ/ios`

The Maou iOS Xcode target copies that directory into the app bundle as `MKXPZ`
when it is non-empty.

## Current dependency build status

The dependency set can be built as static iOS libraries with:

```sh
./ios/Dependencies/build-all.sh iphoneos
./ios/Dependencies/build-all.sh iphonesimulator
```

The script writes generated files under `ios/Dependencies/build/`, which is not
tracked. This currently covers SDL2, SDL2_image, SDL2_ttf, SDL2_sound, OpenAL,
PhysFS, FreeType, libpng, pixman, ogg, vorbis, theora, uchardet, and static Ruby
without the OpenSSL extension. mkxp-z's final static runtime target still needs
to be linked before Maou can start VX Ace games through the embedded bridge.

## Embedded drawable ownership

`Dependencies/patches/sdl2-embedded-drawable.patch` applies to both SDL controller
configurations. In an embedded view, UIKit layout only marks a pending resize.
At a render-frame boundary, `Graphics::checkResize` drains GPU work, releases the
render thread's current EAGL context, and synchronously lends it to the main
thread to allocate drawable storage. The main thread releases it before the
render thread resumes. A weak host disappearing never re-enables unsynchronized
SDL layout. Initial GL setup also releases the main thread's context.

The embedded host owns the SDL view's frame. Detached SDL window/controller
rotation and keyboard callbacks cannot substitute screen coordinates for host
bounds. Rendering uses the completed drawable's pixel dimensions and scale as
one update; it does not combine independent window and drawable size messages.
RGSS `resize_screen` recomputes aspect fit even without a UIKit layout, and wait /
frozen fade loops consume pending layout changes at frame boundaries.

`build-runtime.sh ... --skip-deps` still refreshes the incremental SDL target,
because the embedding bridge requires these patched Objective-C methods. Other
cached dependencies are reused. The patch stamp includes every applied patch;
editing a patch rebuilds the generated source tree.

Apple's [OpenGL ES concurrency guidance](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/ConcurrencyandOpenGLES/ConcurrencyandOpenGLES.html)
requires synchronization for a context accessed by multiple threads. Merely
setting that context current in `layoutSubviews` does not provide synchronization.
