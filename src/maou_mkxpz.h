#ifndef MAOU_MKXPZ_H
#define MAOU_MKXPZ_H
#include <stdint.h>

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
// Optional fixed-renderer service lifecycle. Disabled until begin succeeds.
// Cancel requests bounded Graphics loops to return through normal GL cleanup;
// it does not terminate CRuby/the engine or interrupt arbitrary native I/O.
MAOU_MKXPZ_EXPORT int maou_mkxpz_begin_render_session(uint64_t generation);
MAOU_MKXPZ_EXPORT int maou_mkxpz_cancel_render_session(uint64_t generation);
MAOU_MKXPZ_EXPORT int maou_mkxpz_end_render_session(uint64_t generation);
MAOU_MKXPZ_EXPORT int maou_mkxpz_render_session_state(uint64_t generation);
MAOU_MKXPZ_EXPORT int maou_mkxpz_render_cancelled(void);
MAOU_MKXPZ_EXPORT uint64_t maou_mkxpz_render_generation(void);
MAOU_MKXPZ_EXPORT void maou_mkxpz_send_key(int sdlScancode, int keyDown, int ctrl);
MAOU_MKXPZ_EXPORT void maou_mkxpz_resize(int width, int height);
MAOU_MKXPZ_EXPORT void maou_mkxpz_request_screenshot(
    const char *path,
    MaouMkxpzScreenshotCallback callback,
    void *context
);
// Cancels queued capture only. The caller must drain in-flight render work
// before releasing session files or presenting the next game.
MAOU_MKXPZ_EXPORT void maou_mkxpz_cancel_pending_screenshot(void);
MAOU_MKXPZ_EXPORT void maou_mkxpz_set_resource_callback(
    MaouMkxpzResourceCallback callback,
    void *context
);

#ifdef __cplusplus
}
#endif

#endif
