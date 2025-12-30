// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LuaSwift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "LuaSwift",
            targets: ["LuaSwift"]
        ),
    ],
    targets: [
        // Lua 5.4 C library
        .target(
            name: "CLua",
            path: "Sources/CLua",
            sources: [
                "lapi.c",
                "lauxlib.c",
                "lbaselib.c",
                "lcode.c",
                "lcorolib.c",
                "lctype.c",
                "ldblib.c",
                "ldebug.c",
                "ldo.c",
                "ldump.c",
                "lfunc.c",
                "lgc.c",
                "linit.c",
                "liolib.c",
                "llex.c",
                "lmathlib.c",
                "lmem.c",
                "loadlib.c",
                "lobject.c",
                "lopcodes.c",
                "loslib.c",
                "lparser.c",
                "lstate.c",
                "lstring.c",
                "lstrlib.c",
                "ltable.c",
                "ltablib.c",
                "ltm.c",
                "lundump.c",
                "lutf8lib.c",
                "lvm.c",
                "lzio.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .define("LUA_USE_IOS", .when(platforms: [.iOS])),
                .define("LUA_USE_MACOSX", .when(platforms: [.macOS])),
                .headerSearchPath(".")
            ]
        ),
        // Swift wrapper
        .target(
            name: "LuaSwift",
            dependencies: ["CLua"],
            path: "Sources/LuaSwift",
            exclude: ["LuaModules"],
            resources: [
                .copy("LuaModules")
            ]
        ),
        // Tests
        .testTarget(
            name: "LuaSwiftTests",
            dependencies: ["LuaSwift"]
        ),
    ]
)
