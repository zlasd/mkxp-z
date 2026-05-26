//
//  systemImplApple.m
//  Player
//
//  Created by ゾロアーク on 11/22/20.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import <Metal/Metal.h>

#import <sys/sysctl.h>
#import "system.h"
#if !TARGET_OS_IPHONE
#import "SettingsMenuController.h"
#endif

std::string systemImpl::getSystemLanguage() {
    @autoreleasepool {
        NSString *languageCode = NSLocale.currentLocale.languageCode;
        NSString *countryCode = NSLocale.currentLocale.countryCode;
        return std::string([NSString stringWithFormat:@"%@_%@", languageCode, countryCode].UTF8String);
    }
}

std::string systemImpl::getUserName() {
    @autoreleasepool {
        return std::string(NSUserName().UTF8String);
    }
}

int systemImpl::getScalingFactor() {
#if TARGET_OS_IPHONE
    return UIScreen.mainScreen.scale;
#else
    return NSApplication.sharedApplication.mainWindow.backingScaleFactor;
#endif
}

bool systemImpl::isWine() {
    return false;
}

bool systemImpl::isRosetta() {
#if TARGET_OS_IPHONE
    return false;
#else
    int translated = 0;
    size_t size = sizeof(translated);
    int result = sysctlbyname("sysctl.proc_translated", &translated, &size, NULL, 0);
    
    if (result == -1)
        return false;
    
    return translated;
#endif
}

systemImpl::WineHostType systemImpl::getRealHostType() {
    return WineHostType::Mac;
}


// constant, if it's not nil then just raise the menu instead
#if TARGET_OS_IPHONE
void openSettingsWindow() {}
#else
SettingsMenu *smenu = nil;
void openSettingsWindow() {
    if (smenu == nil) {
        smenu = [SettingsMenu openWindow];
        return;
    }
    [smenu raise];
}
#endif

bool isMetalSupported() {
#if TARGET_OS_IPHONE
    return false;
#else
    if (@available(macOS 10.13.0, *)) {
        return MTLCreateSystemDefaultDevice() != nil;
    }
    return false;
#endif
}

std::string getPlistValue(const char *key) {
    @autoreleasepool {
        NSString *hash = [[NSBundle mainBundle] objectForInfoDictionaryKey:@(key)];
        if (hash != nil) {
            return std::string(hash.UTF8String);
        }
        return "";
    }
}
