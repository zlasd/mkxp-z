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
    int controllerSupportEnabled;
} MaouMkxpzRunOptions;

typedef void (*MaouMkxpzScreenshotCallback)(int success, const char *path, void *context);
typedef void (*MaouMkxpzResourceCallback)(const char *path, void *context);

MAOU_MKXPZ_EXPORT int maou_mkxpz_run(const MaouMkxpzRunOptions *options);
MAOU_MKXPZ_EXPORT void maou_mkxpz_request_stop(void);
MAOU_MKXPZ_EXPORT void maou_mkxpz_send_key(int sdlScancode, int keyDown, int ctrl);
MAOU_MKXPZ_EXPORT void maou_mkxpz_resize(int width, int height);
MAOU_MKXPZ_EXPORT void maou_mkxpz_request_screenshot(
    const char *path,
    MaouMkxpzScreenshotCallback callback,
    void *context
);
MAOU_MKXPZ_EXPORT void maou_mkxpz_set_resource_callback(
    MaouMkxpzResourceCallback callback,
    void *context
);

#ifdef __cplusplus
}
#endif

#endif
