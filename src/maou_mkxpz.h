#ifndef MAOU_MKXPZ_H
#define MAOU_MKXPZ_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define MAOU_MKXPZ_EXPORT __attribute__((visibility("default")))
#else
#define MAOU_MKXPZ_EXPORT
#endif

typedef struct MaouMkxpzRunOptions {
    int argc;
    char **argv;
    const char *workingDirectory;
    const char *resourceDirectory;
    void *nativeView;
    int viewWidth;
    int viewHeight;
} MaouMkxpzRunOptions;

MAOU_MKXPZ_EXPORT int maou_mkxpz_run(const MaouMkxpzRunOptions *options);
MAOU_MKXPZ_EXPORT void maou_mkxpz_request_stop(void);
MAOU_MKXPZ_EXPORT void maou_mkxpz_send_key(int sdlScancode, int keyDown, int ctrl);
MAOU_MKXPZ_EXPORT void maou_mkxpz_resize(int width, int height);

#ifdef __cplusplus
}
#endif

#endif
