#!/usr/bin/env ruby

def run_build
    printf("====================================================\n")
    printf("Building all dependencies. This'll take a while.\n")

    printf("Building libraries for Apple Silicon...\n")
    printf("====================================================\n")
    code = system("make everything -f arm64.make")
    return code if !code

    printf("====================================================\n")
    printf("Apple Silicon dependencies are available in build-macosx-arm64.\n")
    true
end

def fix_steam(libpath)
    # Don't need to do anything if it's already set to runpath
    return 0 if (`otool -L #{libpath}`[/@rpath/])
    printf("Patching Steamworks SDK...\n")
    # Set the install name to runpath
    return 1 if !system("install_name_tool -id @rpath/libsteam_api.dylib #{libpath}")
    # Resign
    return (system("codesign -fs - #{libpath}") ? 0 : 1)
end

exitcode = run_build ? 0 : 1
exit(exitcode) if (exitcode != 0)

STEAM_LIB = "Frameworks/steam/sdk/redistributable_bin/osx/libsteam_api.dylib"
if File.exists?(STEAM_LIB)
    exitcode = fix_steam(STEAM_LIB)
end

printf("Done.\n\n")

exit(exitcode)
