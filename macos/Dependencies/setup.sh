#!/usr/bin/env ruby

HOST = `clang -dumpmachine`.strip
ARCH = HOST[/x86_64|arm64/]
REQUESTED_ARCHS = (ENV["MKXPZ_MACOS_ARCHS"] || "arm64").split(/[,\s]+/).reject(&:empty?)

def run_build(arch)
    printf("====================================================\n")
    printf("Building all dependencies. This'll take a while.\n")

    build_arm64 = REQUESTED_ARCHS.include?("arm64") || REQUESTED_ARCHS.include?("universal")
    build_x86_64 = REQUESTED_ARCHS.include?("x86_64") || REQUESTED_ARCHS.include?("universal")

    if build_arm64 && `xcodebuild -version`.scan(/Xcode (\d+)/)[0][0].to_i >= 12
        printf("Building libraries for Apple Silicon...\n")
        printf("====================================================\n")
        code = system("make everything -f arm64.make")
        return code if !code
    end

    if build_x86_64
        printf("====================================================\n")
        printf("Building libraries for Intel...\n")
        printf("====================================================\n")
        code = (system("make everything -f x86_64.make"))
        return code if !code
    end

    printf("====================================================\n")
    printf("Performing post-setup...\n")
    printf("====================================================\n")

    if build_arm64 && build_x86_64
        printf("Creating universal libraries ...\n")
        return system("./make_macuniversal.sh")
    end

    if build_arm64
        printf("Using Apple Silicon libraries for the project dependency path ...\n")
        return system("rm -rf build-macosx-universal && ditto build-macosx-arm64 build-macosx-universal")
    end

    if build_x86_64
        printf("Using Intel libraries for the project dependency path ...\n")
        return system("rm -rf build-macosx-universal && ditto build-macosx-x86_64 build-macosx-universal")
    end

    printf("No mkxp-z macOS dependency architectures requested.\n")
    return false
end

def fix_steam(libpath)
    # Don't need to do anything if it's already set to runpath
    return 0 if (`otool -L #{libpath}`[/@rpath/])
    printf("Patching Steamworks SDK...\n")
    # Remove 32-bit code from the binary
    if `lipo -info #{libpath}`[/i386/]
        return 1 if !system("lipo -remove i386 #{libpath} -o #{libpath}")
    end
    # Set the install name to runpath
    return 1 if !system("install_name_tool -id @rpath/libsteam_api.dylib #{libpath}")
    # Resign
    return (system("codesign -fs - #{libpath}") ? 0 : 1)
end

exitcode = run_build(ARCH) ? 0 : 1
exit(exitcode) if (exitcode != 0)

STEAM_LIB = "Frameworks/steam/sdk/redistributable_bin/osx/libsteam_api.dylib"
if File.exists?(STEAM_LIB)
    exitcode = fix_steam(STEAM_LIB)
end

printf("Done.\n\n")

exit(exitcode)
