#include <stdio.h>
#include <string.h>
#include "lua_util.h"
#include "b64.h"

static int lua_encode(lua_State *L){
	size_t len;
	const unsigned char *input = (const unsigned char*)lua_tolstring(L,-1,&len);
	lua_pushstring(L,b64_encode(input,len));	
	return 1;	
}

static int lua_decode(lua_State *L){
	size_t len1,len2;
	const char *input = (const char*)lua_tolstring(L,-1,&len1);
	const char *output = (const char*)b64_decode_ex(input,len1,&len2);
	lua_pushlstring(L,output,len2);
	return 1;	
}

int luaopen_base64(lua_State *L) {
    luaL_Reg l[] = {
        {"encode", lua_encode},
        {"decode", lua_decode},
        {NULL, NULL}
    };
    luaL_newlib(L, l);
    return 1;
}
