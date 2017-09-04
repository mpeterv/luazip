/*
 LuaZip - Reading files inside zip files.
 https://github.com/mpeterv/luazip

 Author: Danilo Tuler
 Maintainer: Peter Melnichenko
 Copyright (c) 2003-2007 Kepler Project
 Copyright (c) 2016-2017 Peter Melnichenko
*/

#ifndef luazip_h
#define luazip_h

#include "lua.h"

#ifndef LUAZIP_API
#define LUAZIP_API	LUA_API
#endif

#define LUA_ZIPLIBNAME	"zip"
LUAZIP_API int luaopen_zip (lua_State *L);

#endif
