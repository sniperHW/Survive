/*
    Copyright (C) <2012>  <huangweilook@21cn.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef _LUA_UTIL_H
#define _LUA_UTIL_H
#include <lua.h>  
#include <lauxlib.h>  
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>


typedef struct{
	lua_State     *L;
	int 		   rindex;	
}luaRef_t;

static inline void release_luaRef(luaRef_t *ref)
{
	if(ref->rindex != LUA_REFNIL){
		luaL_unref(ref->L,LUA_REGISTRYINDEX,ref->rindex);
		ref->L = NULL;
		ref->rindex = LUA_REFNIL;
	}
}

static inline luaRef_t toluaRef(lua_State *L,int idx){
	luaRef_t ref = {.L = NULL,.rindex = LUA_REFNIL};
	lua_pushvalue(L,idx);
	if(!lua_istable(L,-1)){
		lua_pop(L,1);
	}else{
		ref.rindex = luaL_ref(L,LUA_REGISTRYINDEX);
		lua_rawgeti(L,  LUA_REGISTRYINDEX, LUA_RIDX_MAINTHREAD);
		ref.L = lua_tothread(L,-1);
		lua_pop(L,1);
	}
	return ref;
}

static inline void push_LuaRef(lua_State *L,luaRef_t ref){
	lua_rawgeti(L,LUA_REGISTRYINDEX,ref.rindex);
}

/* 当ref是一个table时，可通过调用以下两个函数获取和设置table字段
*  fmt "kkkkkk:vvvvv",k,v含义与luacall一致,且数量必须配对
*/
const char *LuaRef_Get(luaRef_t ref,const char *fmt,...);
const char *LuaRef_Set(luaRef_t ref,const char *fmt,...);

/*i:符号整数
* u:无符号整数
* s:字符串,lua_pushstring,lua_tostring
* S:字符串,lua_pushlstring,lua_tolstring,注:S后跟的长度字段必须为size_t/size_t*
* b:布尔值,必须为int/int*
* n:lua number
* r:lua ref
* p:指针(lightuserdata)
*/
const char *luacall(lua_State *L,const char *fmt,...);

#define LuaCall(__L,__FUNC,__FMT, ...)({\
			const char *__result;\
			int __oldtop = lua_gettop(__L);\
			lua_getglobal(__L,__FUNC);\
			__result = luacall(__L,__FMT,##__VA_ARGS__);\
			lua_settop(__L,__oldtop);\
		__result;})

//调用一个lua引用，这个引用是一个函数		
#define LuaCallRefFunc(__FUNREF,__FMT,...)({\
			const char *__result;\
			lua_State *__L = (__FUNREF).L;\
			int __oldtop = lua_gettop(__L);\
			lua_rawgeti(__L,LUA_REGISTRYINDEX,(__FUNREF).rindex);\
			__result = luacall(__L,__FMT,##__VA_ARGS__);\
			lua_settop(__L,__oldtop);\
		__result;})

//调用luatable的一个函数字段,注意此调用方式相当于o:func(),也就是会传递self		
#define LuaCallTabFuncS(__TABREF,__FIELD,__FMT,...)({\
			const char *__result;\
			lua_State *__L = (__TABREF).L;\
			int __oldtop = lua_gettop(__L);\
			lua_rawgeti(__L,LUA_REGISTRYINDEX,(__TABREF).rindex);\
			lua_pushstring(__L,__FIELD);\
			lua_gettable(__L,-2);\
			lua_remove(__L,-2);\
			const char *__fmt = __FMT;\
			if(__fmt){char __tmp[32];\
				snprintf(__tmp,32,"r%s",(const char*)__fmt);\
				__result = luacall(__L,__tmp,__TABREF,##__VA_ARGS__);\
			}else{\
				__result = luacall(__L,"r",__TABREF);\
			}\
			lua_settop(__L,__oldtop);\
		__result;})
		
//调用luatable的一个函数字段,注意此调用方式相当于o.func(),也就是不传递self		
#define LuaCallTabFunc(__TABREF,__FIELD,__FMT,...)({\
			const char *__result;\
			lua_State *__L = (__TABREF).L;\
			int __oldtop = lua_gettop(__L);\
			lua_rawgeti(__L,LUA_REGISTRYINDEX,(__TABREF).rindex);\
			lua_pushstring(__L,__FIELD);\
			lua_gettable(__L,-2);\
			lua_remove(__L,-2);\
			const char *__fmt = __FMT;\
			if(__fmt){char __tmp[32];\
				snprintf(__tmp,32,"r%s",(const char*)__fmt);\
				__result = luacall(__L,__tmp,__TABREF,##__VA_ARGS__);\
			}else{\
				__result = luacall(__L,"r",__TABREF);\
			}\
			lua_settop(__L,__oldtop);\
		__result;})	


#define EnumKey -2
#define EnumVal -1				
#define LuaTabForEach(TABREF)\
			for(lua_rawgeti(TABREF.L,LUA_REGISTRYINDEX,TABREF.rindex),lua_pushnil(TABREF.L);\
				({\
					int __result;\
					do __result = lua_next(TABREF.L,-2);\
					while(0);\
					if(!__result)lua_pop(TABREF.L,1);\
					__result;});lua_pop(TABREF.L,1))

#endif


