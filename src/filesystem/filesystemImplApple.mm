//
//  filesystemImplApple.mm
//  Player
//
//  Created by ゾロアーク on 11/21/20.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#else
#import <AppKit/AppKit.h>
#endif
#import <dispatch/dispatch.h>
#import <SDL.h>
#import <SDL_syswm.h>

#import <SDL_filesystem.h>
#import <mach-o/dyld.h>

#import "filesystemImpl.h"
#import "util/exception.h"
#import "util/debugwriter.h"

#include <vector>

#define PATHTONS(str) [NSFileManager.defaultManager stringWithFileSystemRepresentation:str length:strlen(str)]

#define NSTOPATH(str) [NSFileManager.defaultManager fileSystemRepresentationWithPath:str]

#if TARGET_OS_IPHONE
@protocol MaouSDLDrawableRenderbuffer
- (GLuint)drawableRenderbuffer;
- (GLuint)drawableFramebuffer;
@property (nonatomic, weak) UIView *maouHostView;
- (BOOL)maouSyncDrawableWidth:(int *)width height:(int *)height scale:(float *)scale;
@end

// Render-thread entry: SDL defers UIKit drawable changes until this handoff.
extern "C" bool maou_mkxpz_sync_ios_drawable(SDL_Window *window, int *width,
                                             int *height, float *scale) {
    SDL_SysWMinfo info{};
    SDL_VERSION(&info.version);
    if (!SDL_GetWindowWMInfo(window, &info)) return false;
    id<MaouSDLDrawableRenderbuffer> view = (id)info.info.uikit.window.rootViewController.view;
    return [view maouSyncDrawableWidth:width height:height scale:scale];
}

extern "C" unsigned int maou_mkxpz_ios_drawable_framebuffer(SDL_Window *window) {
    @autoreleasepool {
        if (window == nullptr) {
            return 0;
        }

        SDL_SysWMinfo windowInfo{};
        SDL_VERSION(&windowInfo.version);
        if (!SDL_GetWindowWMInfo(window, &windowInfo)) {
            return 0;
        }

        UIView *sdlView = windowInfo.info.uikit.window.rootViewController.view;
        if (![sdlView respondsToSelector:@selector(drawableFramebuffer)]) {
            return 0;
        }

        return [(id<MaouSDLDrawableRenderbuffer>)sdlView drawableFramebuffer];
    }
}

extern "C" void maou_mkxpz_prepare_ios_gl_present(SDL_Window *window) {
    @autoreleasepool {
        if (window == nullptr) {
            return;
        }

        SDL_SysWMinfo windowInfo{};
        SDL_VERSION(&windowInfo.version);
        if (!SDL_GetWindowWMInfo(window, &windowInfo)) {
            return;
        }

        UIView *sdlView = windowInfo.info.uikit.window.rootViewController.view;
        if (![sdlView respondsToSelector:@selector(drawableRenderbuffer)]) {
            return;
        }

        GLuint renderbuffer = [(id<MaouSDLDrawableRenderbuffer>)sdlView drawableRenderbuffer];
        if (renderbuffer != 0) {
            glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
        }
    }
}
#else
extern "C" unsigned int maou_mkxpz_ios_drawable_framebuffer(SDL_Window *) { return 0; }
extern "C" void maou_mkxpz_prepare_ios_gl_present(SDL_Window *) {}
#endif

extern "C" void maou_mkxpz_embed_sdl_window(SDL_Window *window, void *nativeView) {
    @autoreleasepool {
        if (window == nullptr || nativeView == nullptr) {
            return;
        }

        SDL_SysWMinfo windowInfo{};
        SDL_VERSION(&windowInfo.version);
        if (!SDL_GetWindowWMInfo(window, &windowInfo)) {
            return;
        }

#if TARGET_OS_IPHONE
        UIWindow *sdlWindow = windowInfo.info.uikit.window;
        UIView *sdlView = sdlWindow.rootViewController.view ?: sdlWindow;
        UIView *hostView = (__bridge UIView *)nativeView;
        if (sdlView == nil || hostView == nil) {
            Debug() << "Maou iOS embed skipped nil view"
                    << "sdlWindow=" << (sdlWindow != nil)
                    << "sdlView=" << (sdlView != nil)
                    << "hostView=" << (hostView != nil);
            return;
        }

        Debug() << "Maou iOS embed before"
                << "sdlView=" << NSStringFromClass([sdlView class]).UTF8String
                << "hostBounds=" << NSStringFromCGRect(hostView.bounds).UTF8String
                << "sdlBounds=" << NSStringFromCGRect(sdlView.bounds).UTF8String
                << "windowHidden=" << (sdlWindow.hidden ? 1 : 0);

        sdlWindow.hidden = NO;
        sdlWindow.userInteractionEnabled = NO;
        sdlWindow.opaque = NO;
        sdlWindow.backgroundColor = UIColor.clearColor;
        sdlWindow.windowLevel = UIWindowLevelNormal - 1.0;
        for (UIView *subview in [hostView.subviews copy]) {
            if ([NSStringFromClass([subview class]) hasPrefix:@"SDL_uikit"]) {
                [subview removeFromSuperview];
            }
        }
        [sdlView removeFromSuperview];
        sdlView.hidden = NO;
        sdlView.opaque = YES;
        if ([sdlView respondsToSelector:@selector(setMaouHostView:)]) {
            [(id<MaouSDLDrawableRenderbuffer>)sdlView setMaouHostView:hostView];
        }
        sdlView.frame = hostView.bounds;
        sdlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [hostView addSubview:sdlView];
        [hostView setNeedsLayout];
        [sdlView setNeedsLayout];

        Debug() << "Maou iOS embed after"
                << "hostSubviews=" << hostView.subviews.count
                << "sdlWindowHidden=" << (sdlWindow.hidden ? 1 : 0)
                << "sdlHasSuperview=" << (sdlView.superview == hostView ? 1 : 0)
                << "sdlFrame=" << NSStringFromCGRect(sdlView.frame).UTF8String;
#else
        NSWindow *sdlWindow = windowInfo.info.cocoa.window;
        NSView *sdlView = sdlWindow.contentView;
        NSView *hostView = (__bridge NSView *)nativeView;
        if (sdlView == nil || hostView == nil) {
            return;
        }

        [sdlView removeFromSuperview];
        sdlView.frame = hostView.bounds;
        sdlView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [hostView addSubview:sdlView positioned:NSWindowBelow relativeTo:nil];
        [sdlWindow orderOut:nil];
#endif
    }
}

extern "C" SDL_Window *maou_mkxpz_create_embedded_sdl_window(const char *title,
                                                             int width,
                                                             int height,
                                                             Uint32 flags,
                                                             void *nativeView) {
    __block SDL_Window *window = nullptr;
    NSString *validatedTitle = title != nullptr ? [NSString stringWithUTF8String:title] : nil;
    if (validatedTitle == nil) {
        validatedTitle = @"Maou Console";
    }
    void (^createWindow)(void) = ^{
        window = SDL_CreateWindow(validatedTitle.UTF8String,
                                  0,
                                  0,
                                  width,
                                  height,
                                  flags | SDL_WINDOW_BORDERLESS);
        maou_mkxpz_embed_sdl_window(window, nativeView);
    };

    if ([NSThread isMainThread]) {
        createWindow();
    } else {
        dispatch_sync(dispatch_get_main_queue(), createWindow);
    }

    return window;
}

static NSString *mkxpExecutableResourcePath() {
    uint32_t size = 0;
    _NSGetExecutablePath(nullptr, &size);
    std::vector<char> path(size + 1);
    if (_NSGetExecutablePath(path.data(), &size) != 0) {
        return nil;
    }

    NSString *executablePath = [NSFileManager.defaultManager
        stringWithFileSystemRepresentation:path.data()
                                    length:strlen(path.data())];
    NSString *resourcesPath = [[executablePath stringByDeletingLastPathComponent]
        stringByAppendingPathComponent:@"../Resources"];
    return [resourcesPath stringByStandardizingPath];
}

static NSString *mkxpResourcePath() {
    const char *maouResourcePath = SDL_getenv("MAOU_MKXPZ_RESOURCE_PATH");
    if (maouResourcePath && *maouResourcePath) {
        NSString *resourcePath = PATHTONS(maouResourcePath);
        NSString *assetBundle = [resourcePath stringByAppendingPathComponent:@"Assets.bundle"];
        if ([NSFileManager.defaultManager fileExistsAtPath:assetBundle]) {
            return resourcePath;
        }
    }

    NSString *bundleResourcePath = NSBundle.mainBundle.resourcePath;
    if (bundleResourcePath != nil) {
        NSString *assetBundle = [bundleResourcePath stringByAppendingPathComponent:@"Assets.bundle"];
        if ([NSFileManager.defaultManager fileExistsAtPath:assetBundle]) {
            return bundleResourcePath;
        }
    }

    NSString *executableResourcePath = mkxpExecutableResourcePath();
    if (executableResourcePath != nil) {
        return executableResourcePath;
    }

    return bundleResourcePath;
}

bool filesystemImpl::fileExists(const char *path) {
    @autoreleasepool{
        BOOL isDir;
        return  [NSFileManager.defaultManager fileExistsAtPath:PATHTONS(path) isDirectory: &isDir] && !isDir;
    }
}



std::string filesystemImpl::contentsOfFileAsString(const char *path) {
    @autoreleasepool {
        NSString *fileContents = [NSString stringWithContentsOfFile: PATHTONS(path)];
        if (fileContents == nil)
            throw Exception(Exception::NoFileError, "Failed to read file at %s", path);
        
        return std::string(fileContents.UTF8String);
    }
}


bool filesystemImpl::setCurrentDirectory(const char *path) {
    @autoreleasepool {
        return [NSFileManager.defaultManager changeCurrentDirectoryPath: PATHTONS(path)];
    }
}

std::string filesystemImpl::getCurrentDirectory() {
    @autoreleasepool {
        return std::string(NSTOPATH(NSFileManager.defaultManager.currentDirectoryPath));
    }
}

std::string filesystemImpl::normalizePath(const char *path, bool preferred, bool absolute) {
    @autoreleasepool {
        NSString *inputPath = PATHTONS(path);
        NSString *nspath;
        if (!absolute && !inputPath.isAbsolutePath) {
            nspath = inputPath.stringByStandardizingPath;
        } else {
            nspath = [NSURL fileURLWithPath:inputPath].URLByStandardizingPath.path;
            NSString *pwd = [NSString stringWithFormat:@"%@/", NSFileManager.defaultManager.currentDirectoryPath];
            if (!absolute && [nspath hasPrefix:pwd]) {
                nspath = [nspath substringFromIndex:pwd.length];
            }
        }
        nspath = [nspath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        nspath = [nspath precomposedStringWithCanonicalMapping];
        if (!absolute) {
            return std::string(nspath.UTF8String);
        }
        return std::string(NSTOPATH(nspath));
    }
}

std::string filesystemImpl::getDefaultGameRoot() {
    @autoreleasepool {
        NSString *bundlePath = NSBundle.mainBundle.bundlePath;
        if (bundlePath == nil || ![NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingPathComponent:@"Contents/Game"]]) {
            NSString *resourcePath = mkxpResourcePath();
            bundlePath = [[resourcePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        }
        NSString *p = [NSString stringWithFormat: @"%@/%s", bundlePath, "Contents/Game"];
        return std::string(NSTOPATH(p));
    }
}

NSString *getPathForAsset_internal(const char *baseName, const char *ext) {
    NSString *resourcePath = mkxpResourcePath();
    NSBundle *assetBundle = [NSBundle bundleWithPath:
                             [NSString stringWithFormat:
                              @"%@/%s",
                              resourcePath,
                              "Assets.bundle"
                             ]
                            ];
    
    if (assetBundle == nil)
        return nil;
    
    return [assetBundle pathForResource: @(baseName) ofType: @(ext)];
}

std::string filesystemImpl::getPathForAsset(const char *baseName, const char *ext) {
    @autoreleasepool {
        NSString *assetPath = getPathForAsset_internal(baseName, ext);
        if (assetPath == nil)
            throw Exception(Exception::NoFileError, "Failed to find the asset named %s.%s", baseName, ext);
        
        return std::string(NSTOPATH(getPathForAsset_internal(baseName, ext)));
    }
}

std::string filesystemImpl::contentsOfAssetAsString(const char *baseName, const char *ext) {
    @autoreleasepool {
        NSString *path = getPathForAsset_internal(baseName, ext);
        if (path == nil)
            throw Exception(Exception::NoFileError, "Failed to find asset %s.%s", baseName, ext);
        NSString *fileContents = [NSString stringWithContentsOfFile: path];
        
        // This should never fail
        if (fileContents == nil)
            throw Exception(Exception::MKXPError, "Failed to read file at %s", path.UTF8String);
        
        return std::string(fileContents.UTF8String);
    }
}

std::string filesystemImpl::getResourcePath() {
    @autoreleasepool {
        return std::string(NSTOPATH(mkxpResourcePath()));
    }
}

std::string filesystemImpl::selectPath(SDL_Window *win, const char *msg, const char *prompt) {
    @autoreleasepool {
#if TARGET_OS_IPHONE
        return std::string();
#else
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.canChooseDirectories = true;
        panel.canChooseFiles = false;
        
        if (msg) panel.message = @(msg);
        if (prompt) panel.prompt = @(prompt);
        //panel.directoryURL = [NSURL fileURLWithPath:NSFileManager.defaultManager.currentDirectoryPath];
        
        SDL_SysWMinfo windowinfo{};
        SDL_GetWindowWMInfo(win, &windowinfo);
        
        [panel beginSheetModalForWindow:windowinfo.info.cocoa.window completionHandler:^(NSModalResponse res){
            [NSApp stopModalWithCode:res];
        }];
        
        [NSApp runModalForWindow:windowinfo.info.cocoa.window];
        
        // The window needs to be brought to the front again after the OpenPanel closes
        [windowinfo.info.cocoa.window makeKeyAndOrderFront:nil];
        if (panel.URLs.count > 0)
            return std::string(NSTOPATH(panel.URLs[0].path));
        
        return std::string();
#endif
    }
}
