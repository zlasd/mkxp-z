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
