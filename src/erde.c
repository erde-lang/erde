#include "./parser.h"
#include <lauxlib.h>
#include <lua.h>

static int
erde_compile(lua_State* L)
{
  const char* source = luaL_checkstring(L, 1);
  const char* compiled = compile(source);
  lua_pushstring(L, compiled);
  return 1;
}

static const struct luaL_Reg erdec[] = { { "compile", erde_compile },
                                         { NULL, NULL } };

int
luaopen_erdec(lua_State* L)
{
  luaL_newlib(L, erdec);
  return 1;
}
