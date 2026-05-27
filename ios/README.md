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
