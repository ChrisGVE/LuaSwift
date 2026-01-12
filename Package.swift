// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// MARK: - Lua Version Selection
// Set LUASWIFT_LUA_VERSION environment variable to select Lua version:
//   51 = Lua 5.1.5
//   52 = Lua 5.2.4
//   53 = Lua 5.3.6
//   54 = Lua 5.4.7 (default)
//   55 = Lua 5.5.0
// Example: LUASWIFT_LUA_VERSION=53 swift build

let luaVersion = ProcessInfo.processInfo.environment["LUASWIFT_LUA_VERSION"] ?? "54"
let validVersions = ["51", "52", "53", "54", "55"]
let selectedVersion = validVersions.contains(luaVersion) ? luaVersion : "54"

// Map version to directory path
let cluaPath: String = {
    switch selectedVersion {
    case "51": return "Sources/CLua51"
    case "52": return "Sources/CLua52"
    case "53": return "Sources/CLua53"
    case "55": return "Sources/CLua55"
    default: return "Sources/CLua"
    }
}()

// MARK: - Source Files per Version

let lua51Sources = [
    "lapi.c", "lauxlib.c", "lbaselib.c", "lcode.c", "ldblib.c", "ldebug.c",
    "ldo.c", "ldump.c", "lfunc.c", "lgc.c", "linit.c", "liolib.c", "llex.c",
    "lmathlib.c", "lmem.c", "loadlib.c", "lobject.c", "lopcodes.c", "loslib.c",
    "lparser.c", "lstate.c", "lstring.c", "lstrlib.c", "ltable.c", "ltablib.c",
    "ltm.c", "lundump.c", "lvm.c", "lzio.c"
]

let lua52Sources = [
    "lapi.c", "lauxlib.c", "lbaselib.c", "lbitlib.c", "lcode.c", "lcorolib.c",
    "lctype.c", "ldblib.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c",
    "linit.c", "liolib.c", "llex.c", "lmathlib.c", "lmem.c", "loadlib.c",
    "lobject.c", "lopcodes.c", "loslib.c", "lparser.c", "lstate.c", "lstring.c",
    "lstrlib.c", "ltable.c", "ltablib.c", "ltm.c", "lundump.c", "lvm.c", "lzio.c"
]

let lua53Sources = [
    "lapi.c", "lauxlib.c", "lbaselib.c", "lbitlib.c", "lcode.c", "lcorolib.c",
    "lctype.c", "ldblib.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c",
    "linit.c", "liolib.c", "llex.c", "lmathlib.c", "lmem.c", "loadlib.c",
    "lobject.c", "lopcodes.c", "loslib.c", "lparser.c", "lstate.c", "lstring.c",
    "lstrlib.c", "ltable.c", "ltablib.c", "ltm.c", "lundump.c", "lutf8lib.c",
    "lvm.c", "lzio.c"
]

let lua54Sources = [
    "lapi.c", "lauxlib.c", "lbaselib.c", "lcode.c", "lcorolib.c", "lctype.c",
    "ldblib.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c", "linit.c",
    "liolib.c", "llex.c", "lmathlib.c", "lmem.c", "loadlib.c", "lobject.c",
    "lopcodes.c", "loslib.c", "lparser.c", "lstate.c", "lstring.c", "lstrlib.c",
    "ltable.c", "ltablib.c", "ltm.c", "lundump.c", "lutf8lib.c", "lvm.c", "lzio.c"
]

let lua55Sources = [
    "lapi.c", "lauxlib.c", "lbaselib.c", "lcode.c", "lcorolib.c", "lctype.c",
    "ldblib.c", "ldebug.c", "ldo.c", "ldump.c", "lfunc.c", "lgc.c", "linit.c",
    "liolib.c", "llex.c", "lmathlib.c", "lmem.c", "loadlib.c", "lobject.c",
    "lopcodes.c", "loslib.c", "lparser.c", "lstate.c", "lstring.c", "lstrlib.c",
    "ltable.c", "ltablib.c", "ltm.c", "lundump.c", "lutf8lib.c", "lvm.c", "lzio.c"
]

let cluaSources: [String] = {
    switch selectedVersion {
    case "51": return lua51Sources
    case "52": return lua52Sources
    case "53": return lua53Sources
    case "55": return lua55Sources
    default: return lua54Sources
    }
}()

// MARK: - Package Definition

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
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(path: "../PlotSwift"),
        .package(path: "../ArraySwift"),
        .package(path: "../NumericSwift"),
    ],
    targets: [
        // Lua C library - version selected by LUASWIFT_LUA_VERSION env var
        .target(
            name: "CLua",
            path: cluaPath,
            sources: cluaSources,
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
            dependencies: [
                "CLua",
                "PlotSwift",
                "ArraySwift",
                "NumericSwift",
                .product(name: "Yams", package: "Yams"),
                .product(name: "TOMLKit", package: "TOMLKit"),
            ],
            path: "Sources/LuaSwift",
            exclude: ["LuaModules"],
            resources: [
                .copy("LuaModules")
            ],
            swiftSettings: [
                .define("LUA_VERSION_\(selectedVersion)")
            ]
        ),
        // Tests
        .testTarget(
            name: "LuaSwiftTests",
            dependencies: ["LuaSwift"]
        ),
    ]
)
