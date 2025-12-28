# Lua 5.4 C Source

This directory contains the Lua 5.4 C source code.

## Setup Instructions

1. Download Lua 5.4.7 from https://www.lua.org/ftp/lua-5.4.7.tar.gz

2. Extract and copy the source files:
   ```bash
   tar xzf lua-5.4.7.tar.gz
   cp lua-5.4.7/src/*.c Sources/CLua/
   cp lua-5.4.7/src/*.h Sources/CLua/include/
   ```

3. Remove the standalone interpreter files (not needed for embedding):
   ```bash
   rm Sources/CLua/lua.c      # Standalone interpreter
   rm Sources/CLua/luac.c     # Standalone compiler
   ```

## Files Required

### Header files (in `include/`):
- lua.h
- luaconf.h
- lualib.h
- lauxlib.h

### Source files:
- lapi.c
- lauxlib.c
- lbaselib.c
- lcode.c
- lcorolib.c
- lctype.c
- ldblib.c
- ldebug.c
- ldo.c
- ldump.c
- lfunc.c
- lgc.c
- linit.c
- liolib.c
- llex.c
- lmathlib.c
- lmem.c
- loadlib.c
- lobject.c
- lopcodes.c
- loslib.c
- lparser.c
- lstate.c
- lstring.c
- lstrlib.c
- ltable.c
- ltablib.c
- ltm.c
- lundump.c
- lutf8lib.c
- lvm.c
- lzio.c

## License

Lua is MIT licensed. See https://www.lua.org/license.html
