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
#ifdef USE_LUAJIT
#include <luajit-2.0/lua.h>  
#include <luajit-2.0/lauxlib.h>  
#include <luajit-2.0/lualib.h>
#else
#include <lua.h>  
#include <lauxlib.h>  
#include <lualib.h>
#endif 
#include <stdio.h>
#include <stdlib.h>

static inline int _traceback (lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if (msg)
    luaL_traceback(L, L, msg, 1);
  else if (!lua_isnoneornil(L, 1)) {  /* is there an error object? */
    if (!luaL_callmeta(L, 1, "__tostring"))  /* try its 'tostring' metamethod */
      lua_pushliteral(L, "(no error message)");
  }
  return 1;
}

//call lua function
#define LuaCall0(LUASTATE,FUNCNAME,RET)\
		({\
			lua_getglobal(LUASTATE,FUNCNAME);\
			int ___base = lua_gettop(LUASTATE) - 0;\
			lua_pushcfunction(LUASTATE, _traceback);\
			lua_insert(LUASTATE, ___base);\
			const char * ___err = NULL;\
			if(lua_pcall(LUASTATE,0,RET,___base)){\
				___err = lua_tostring(LUASTATE,-1);\
				lua_pop(LUASTATE,1);\
			}\
			lua_remove(LUASTATE,___base);\
			___err;})

#define LuaCall1(LUASTATE,FUNCNAME,RET,ARG1)\
		({\
			lua_getglobal(LUASTATE,FUNCNAME);\
			ARG1;\
			int ___base = lua_gettop(LUASTATE) - 1;\
			lua_pushcfunction(LUASTATE, _traceback);\
			lua_insert(LUASTATE, ___base);\
			const char * ___err = NULL;\
			if(lua_pcall(LUASTATE,1,RET,0)){\
				___err = lua_tostring(LUASTATE,-1);\
				lua_pop(LUASTATE,1);\
			}\
			lua_remove(LUASTATE,___base);\
			___err;})

#define LuaCall2(LUASTATE,FUNCNAME,RET,ARG1,ARG2)\
		({\
			lua_getglobal(LUASTATE,FUNCNAME);\
			ARG1;ARG2;\
			int ___base = lua_gettop(LUASTATE) - 2;\
			lua_pushcfunction(LUASTATE, _traceback);\
			lua_insert(LUASTATE, ___base);\
			const char * ___err = NULL;\
			if(lua_pcall(LUASTATE,2,RET,0)){\
				___err = lua_tostring(LUASTATE,-1);\
				lua_pop(LUASTATE,1);\
			}\
			lua_remove(LUASTATE,___base);\
			___err;})
		
#define LuaCall3(LUASTATE,FUNCNAME,RET,ARG1,ARG2,ARG3)\
		({\
			lua_getglobal(LUASTATE,FUNCNAME);\
			ARG1;ARG2;ARG3;\
			int ___base = lua_gettop(LUASTATE) - 3;\
			lua_pushcfunction(LUASTATE, _traceback);\
			lua_insert(LUASTATE, ___base);\
			const char * ___err = NULL;\
			if(lua_pcall(LUASTATE,3,RET,0)){\
				___err = lua_tostring(LUASTATE,-1);\
				lua_pop(LUASTATE,1);\
			}\
			lua_remove(LUASTATE,___base);\
			___err;})
		
#define LuaCall4(LUASTATE,FUNCNAME,RET,ARG1,ARG2,ARG3,ARG4)\
		({\
			lua_getglobal(LUASTATE,FUNCNAME);\
			ARG1;ARG2;ARG3;ARG4;\
			int ___base = lua_gettop(LUASTATE) - 4;\
			lua_pushcfunction(LUASTATE, _traceback);\
			lua_insert(LUASTATE, ___base);\
			const char * ___err = NULL;\
			if(lua_pcall(LUASTATE,4,RET,0)){\
				___err = lua_tostring(LUASTATE,-1);\
				lua_pop(LUASTATE,1);\
			}\
			lua_remove(LUASTATE,___base);\
			___err;})

//lua表的一个引用
typedef struct
{
	lua_State      *L;
	int 		   rindex;	
}luaTabRef_t;

static inline luaTabRef_t create_luaTabRef(lua_State *L,int idx)
{
	luaTabRef_t o = {.L=NULL,.rindex=LUA_REFNIL};
	lua_pushvalue(L,idx);
	if(!lua_istable(L,-1)){
		lua_pop(L,1);
	}else{
		o.L = L;
		o.rindex = luaL_ref(L,LUA_REGISTRYINDEX);
	}
	return o;
}

static inline int  isVaild_TabRef(luaTabRef_t o){
	return o.rindex != LUA_REFNIL;
}

static inline void release_luaTabRef(luaTabRef_t *o)
{
	if(o->rindex != LUA_REFNIL){
		luaL_unref(o->L,LUA_REGISTRYINDEX,o->rindex);
		o->L = NULL;
		o->rindex = LUA_REFNIL;
	}
}

#define CallLuaTabFunc0(LSTATE,TABREF,FUNCNAME,RET)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (TABREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,FUNCNAME);\
			lua_gettable(___L,-2);\
			lua_insert(___L,-2);\
			int ___base = lua_gettop(___L) - 1;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			const char *___err = NULL;\
			if(lua_pcall(___L,1,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaTabFunc1(LSTATE,TABREF,FUNCNAME,RET,ARG1)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (TABREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,FUNCNAME);\
			lua_gettable(___L,-2);\
			lua_insert(___L,-2);\
			ARG1;\
			int ___base = lua_gettop(___L) - 2;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			const char *___err = NULL;\
			if(lua_pcall(___L,2,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaTabFunc2(LSTATE,TABREF,FUNCNAME,RET,ARG1,ARG2)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (TABREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,FUNCNAME);\
			lua_gettable(___L,-2);\
			lua_insert(___L,-2);\
			ARG1;ARG2;\
			int ___base = lua_gettop(___L) - 3;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			const char *___err = NULL;\
			if(lua_pcall(___L,3,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})	
			
#define CallLuaTabFunc3(LSTATE,TABREF,FUNCNAME,RET,ARG1,ARG2,ARG3)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (TABREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,FUNCNAME);\
			lua_gettable(___L,-2);\
			lua_insert(___L,-2);\
			ARG1;ARG2;ARG3;\
			const char *___err = NULL;\
			int ___base = lua_gettop(___L) - 4;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,4,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaTabFunc4(LSTATE,TABREF,FUNCNAME,RET,ARG1,ARG2,ARG3,ARG4)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (TABREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,FUNCNAME);\
			lua_gettable(___L,-2);\
			lua_insert(___L,-2);\
			ARG1;ARG2;ARG3;ARG4;\
			const char *___err = NULL;\
			int ___base = lua_gettop(___L) - 5;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,5,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})

#define EnumKey -2
#define EnumVal -1				
#define LuaTabEnum(TABREF)\
			for(lua_rawgeti(TABREF.L,LUA_REGISTRYINDEX,TABREF.rindex),lua_pushnil(TABREF.L);\
				({\
					int __result;\
					do __result = lua_next(TABREF.L,-2);\
					while(0);\
					if(!__result)lua_pop(TABREF.L,1);\
					__result;});lua_pop(TABREF.L,1))


#define LuaTabRefGet(TABREF,NAME,TYPE,TO)\
		({\
			TYPE __result;\
			lua_State *___L = (TABREF).L;\
			int ___oldtop = lua_gettop(___L);\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(TABREF).rindex);\
			lua_pushstring(___L,NAME);\
			lua_gettable(___L,-2);\
			__result = (TYPE)TO(___L,-1);\
			lua_settop(___L,___oldtop);\
		__result;})
		
#define PushLuaTabRef(LUASTATE,TABREF)\
        do{\
            lua_rawgeti(LUASTATE,LUA_REGISTRYINDEX,(TABREF).rindex);\
        }while(0)

//lua函数的一个引用        
typedef struct
{
	lua_State      *L;
	int 		   rindex;	
}luaFuncRef_t;

static inline luaFuncRef_t create_luaFuncRef(lua_State *L,int idx)
{
	luaFuncRef_t o = {.L=NULL,.rindex=LUA_REFNIL};
	lua_pushvalue(L,idx);
	if(lua_isfunction(L,-1) && !lua_iscfunction(L,-1)){
		o.L = L;
		o.rindex = luaL_ref(L,LUA_REGISTRYINDEX);
	}else{
		lua_pop(L,1);
	}
	return o;
}

static inline int  isVaild_FuncRef(luaFuncRef_t o){
	return o.rindex != LUA_REFNIL;
}

static inline void release_luaFuncRef(luaFuncRef_t *o)
{
	if(o->rindex != LUA_REFNIL){
		luaL_unref(o->L,LUA_REGISTRYINDEX,o->rindex);
		o->L = NULL;
		o->rindex = LUA_REFNIL;
	}
}

#define CallLuaFuncRef0(LSTATE,FUNCREF,RET)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (FUNCREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
			const char * ___err = NULL;\
			int ___base = lua_gettop(___L) - 0;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,0,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaFuncRef1(LSTATE,FUNCREF,RET,ARG1)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (FUNCREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
			ARG1;\
			const char * ___err = NULL;\
			int ___base = lua_gettop(___L) - 1;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,1,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaFuncRef2(LSTATE,FUNCREF,RET,ARG1,ARG2)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (FUNCREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
			ARG1;ARG2;\
			const char * ___err = NULL;\
			int ___base = lua_gettop(___L) - 2;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,2,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define CallLuaFuncRef3(LSTATE,FUNCREF,RET,ARG1,ARG2,ARG3)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (FUNCREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
			ARG1;ARG2;ARG3;\
			const char * ___err = NULL;\
			int ___base = lua_gettop(___L) - 3;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,3,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
			
#define CallLuaFuncRef4(LSTATE,FUNCREF,RET,ARG1,ARG2,ARG3,ARG4)\
		({\
			lua_State *___L = LSTATE;\
			if(!___L) ___L = (FUNCREF).L;\
			lua_rawgeti(___L,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
			ARG1;ARG2;ARG3;ARG4;\
			const char * ___err = NULL;\
			int ___base = lua_gettop(___L) - 4;\
			lua_pushcfunction(___L, _traceback);\
			lua_insert(___L, ___base);\
			if(lua_pcall(___L,4,RET,0)){\
				___err = lua_tostring(___L,-1);\
				lua_pop(___L,1);\
			}\
			lua_remove(___L,___base);\
			___err;})
			
#define PushLuaFuncRef(LUASTATE,FUNCREF)\
        do{\
            lua_rawgeti(LUASTATE,LUA_REGISTRYINDEX,(FUNCREF).rindex);\
        }while(0)															        		

#endif
