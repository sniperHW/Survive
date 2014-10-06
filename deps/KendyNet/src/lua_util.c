#include "lua_util.h"
#include <stdarg.h>
#include <assert.h>
#include <string.h>

static inline int __traceback (lua_State *L) {
  const char *msg = lua_tostring(L, 1);
  if(msg)
    luaL_traceback(L, L, msg, 1);
  else if (!lua_isnoneornil(L, 1)) {  /* is there an error object? */
    if (!luaL_callmeta(L, 1, "__tostring"))  /* try its 'tostring' metamethod */
      lua_pushliteral(L, "(no error message)");
  }
  return 1;
}    

static __thread char lua_errmsg[4096];
const char *luacall(lua_State *L,const char *fmt,...){
	assert(L);
	va_list vl;
	int ret,narg,nres,i;
	va_start(vl,fmt);
	int size = fmt?strlen(fmt):0;
	const char *errmsg = NULL;
	//压入参数
	for(narg=0; narg < size; ++narg){
		switch(*fmt++){
			case 'i':{lua_pushnumber(L,va_arg(vl,int));break;}
			case 'u':{lua_pushunsigned(L,va_arg(vl,unsigned int));break;}
			case 's':{lua_pushstring(L,va_arg(vl,char*));break;}
			case 'S':{
				char *str = va_arg(vl,char*);
				lua_pushlstring(L,str,va_arg(vl,size_t));
				break;
			}
			case 'b':{lua_pushboolean(L,va_arg(vl,int));break;}
			case 'n':{lua_pushnumber(L,va_arg(vl,double));break;}
			case 'p':{lua_pushlightuserdata(L,va_arg(vl,void*));break;}
			case 'r':{
				luaRef_t ref = va_arg(vl,luaRef_t);
				lua_rawgeti(L,LUA_REGISTRYINDEX,ref.rindex);
				break;
			}
			case ':':{goto arg_end;}
			default:{
				snprintf(lua_errmsg,4096,"invaild operation(%c)",*fmt);
				errmsg = lua_errmsg;
				goto end;
			}
		}
	}
arg_end:	
	nres = fmt?strlen(fmt):0;
	//插入错误处理函数	
	int base = lua_gettop(L) - narg;
	lua_pushcfunction(L, __traceback);
	lua_insert(L,base);	
	ret = lua_pcall(L,narg,nres,base);
	lua_remove(L,base);
	if(ret){
		strncpy(lua_errmsg,lua_tostring(L,-1),4096);
		return lua_errmsg;
	}else if(nres){
		i = 1;
		for(;nres > 0; --nres,++i){
			switch(*fmt++){
				case 'i':{
					*va_arg(vl,int*) = lua_tointeger(L,i);
					break;
				}
				case 'u':{
					*va_arg(vl,unsigned int*) = lua_tounsigned(L,i);
					break;
				}
				case 's':{
					*va_arg(vl,char**) = (char*)lua_tostring(L,i);
					break;
				}
				case 'S':{
					size_t l;
					*va_arg(vl,char**) = (char*)lua_tolstring(L,i,&l);
					*va_arg(vl,size_t*) = l;
					break;
				}
				case 'b':{
					*va_arg(vl,int*) = (int)lua_toboolean(L,i);
					break;
				}
				case 'n':{
					*va_arg(vl,double*) = lua_tonumber(L,i);
					break;
				}
				case 'p':{					
					*va_arg(vl,void**) = lua_touserdata(L,i);
					break;
				}
				case 'r':{
					lua_pushvalue(L,i);					
					luaRef_t* ref = va_arg(vl,luaRef_t*);
					//保证ref-L是主线程的lua_State
					ref->rindex = luaL_ref(L,LUA_REGISTRYINDEX);  
					//ref->L = L;
					lua_rawgeti(L,  LUA_REGISTRYINDEX, LUA_RIDX_MAINTHREAD);
					ref->L = lua_tothread(L,-1);
					lua_pop(L,1);
					break;
				}
				default:{
					snprintf(lua_errmsg,4096,"invaild operation(%c)",*fmt);
					errmsg = lua_errmsg;
					goto end;					
				}
			}			
		}
	}
end:	
	va_end(vl);
	return errmsg;
}

const char *LuaRef_Get(luaRef_t tab,const char *fmt,...){
	assert(tab.L);
	assert(fmt);
	assert(tab.rindex != LUA_REFNIL);
	int i;
	va_list vl;	
	va_start(vl,fmt);
	const char *errmsg = NULL;	
	lua_State *L = tab.L;
    int oldtop = lua_gettop(L);
	lua_rawgeti(L,LUA_REGISTRYINDEX,tab.rindex);
	if(!lua_istable(L,-1)){
		snprintf(lua_errmsg,4096,"arg1 is not a lua table");		
		errmsg = lua_errmsg;
		goto end;	
	}
	int size = strlen(fmt);
	if(size < 3 || fmt[size/2] != ':'){
		snprintf(lua_errmsg,4096,"fmt invaild(kkkk:vvvv)");
		errmsg = lua_errmsg;
		goto end;		
	}
	size /= 2;
    for(i = 0; i < size;++i){
	   //push key
	   int k = i;	
		switch(fmt[k]){
			case 'i':{lua_pushnumber(L,va_arg(vl,int));break;}
			case 'u':{lua_pushunsigned(L,va_arg(vl,unsigned int));break;}
			case 's':{lua_pushstring(L,va_arg(vl,char*));break;}
			case 'S':{
				char *str = va_arg(vl,char*);
				lua_pushlstring(L,str,va_arg(vl,size_t));
				break;
			}
			case 'b':{lua_pushboolean(L,va_arg(vl,int));break;}
			case 'n':{lua_pushnumber(L,va_arg(vl,double));break;}
			case 'p':{lua_pushlightuserdata(L,va_arg(vl,void*));break;}
			case 'r':{
				luaRef_t ref = va_arg(vl,luaRef_t);
				lua_rawgeti(L,LUA_REGISTRYINDEX,ref.rindex);
				break;
			}
			default:{
				snprintf(lua_errmsg,4096,"invaild operation(%c)",fmt[k]);
				errmsg = lua_errmsg;
				goto end;	
			}
		}
		
		lua_gettable(L,-2);	
		//get value
		int v = k + size + 1;
		switch(fmt[v]){
			case 'i':{
				*va_arg(vl,int*) = lua_tointeger(L,-1);
				break;
			}
			case 'u':{
				*va_arg(vl,unsigned int*) = lua_tounsigned(L,-1);
				break;
			}
			case 's':{
				*va_arg(vl,char**) = (char*)lua_tostring(L,-1);
				break;
			}
			case 'S':{
				size_t l;
				*va_arg(vl,char**) = (char*)lua_tolstring(L,-1,&l);
				*va_arg(vl,size_t*) = l;
				break;
			}
			case 'b':{
				*va_arg(vl,int*) = (int)lua_toboolean(L,-1);
				break;
			}
			case 'n':{
				*va_arg(vl,double*) = lua_tonumber(L,-1);
				break;
			}
			case 'p':{					
				*va_arg(vl,void**) = lua_touserdata(L,-1);
				break;
			}
			case 'r':{
				lua_pushvalue(L,-1);					
				luaRef_t* ref = va_arg(vl,luaRef_t*);
				//保证ref-L是主线程的lua_State
				ref->rindex = luaL_ref(L,LUA_REGISTRYINDEX);
				lua_rawgeti(L,  LUA_REGISTRYINDEX, LUA_RIDX_MAINTHREAD);
				ref->L = lua_tothread(L,-1);
				lua_pop(L,1);
				break;
			}
			default:{
				snprintf(lua_errmsg,4096,"invaild operation(%c)",fmt[v]);
				errmsg = lua_errmsg;
				goto end;					
			}
		}
		lua_pop(L,1);//pop the value
	}					
end:
	lua_settop(L,oldtop);
	va_end(vl);
	return errmsg;
}

const char *LuaRef_Set(luaRef_t tab,const char *fmt,...){
	assert(tab.L);
	assert(fmt);
	assert(tab.rindex != LUA_REFNIL);
	int i;
	va_list vl;	
	va_start(vl,fmt);
	const char *errmsg = NULL;	
	lua_State *L = tab.L;
    int oldtop = lua_gettop(L);
	lua_rawgeti(L,LUA_REGISTRYINDEX,tab.rindex);
	if(!lua_istable(L,-1)){
		snprintf(lua_errmsg,4096,"arg1 is not a lua table");		
		errmsg = lua_errmsg;
		goto end;	
	}
	int size = strlen(fmt);
	if(size < 3 || fmt[size/2] != ':'){
		snprintf(lua_errmsg,4096,"fmt invaild(kkkk:vvvv)");
		errmsg = lua_errmsg;
		goto end;		
	}
	size /= 2;
    for(i = 0; i < size;++i){
	   //push key
	   int k = i;	
		switch(fmt[k]){
			case 'i':{lua_pushnumber(L,va_arg(vl,int));break;}
			case 'u':{lua_pushunsigned(L,va_arg(vl,unsigned int));break;}
			case 's':{lua_pushstring(L,va_arg(vl,char*));break;}
			case 'S':{
				char *str = va_arg(vl,char*);
				lua_pushlstring(L,str,va_arg(vl,size_t));
				break;
			}
			case 'b':{lua_pushboolean(L,va_arg(vl,int));break;}
			case 'n':{lua_pushnumber(L,va_arg(vl,double));break;}
			case 'p':{lua_pushlightuserdata(L,va_arg(vl,void*));break;}
			case 'r':{
				luaRef_t ref = va_arg(vl,luaRef_t);
				lua_rawgeti(L,LUA_REGISTRYINDEX,ref.rindex);
				break;
			}
			default:{
				snprintf(lua_errmsg,4096,"invaild operation(%c)",fmt[k]);
				errmsg = lua_errmsg;
				goto end;	
			}
		}
		//push value
		int v = k + size + 1;
		switch(fmt[v]){
			case 'i':{lua_pushnumber(L,va_arg(vl,int));break;}
			case 'u':{lua_pushunsigned(L,va_arg(vl,unsigned int));break;}
			case 's':{lua_pushstring(L,va_arg(vl,char*));break;}
			case 'S':{
				char *str = va_arg(vl,char*);
				lua_pushlstring(L,str,va_arg(vl,size_t));
				break;
			}
			case 'b':{lua_pushboolean(L,va_arg(vl,int));break;}
			case 'n':{lua_pushnumber(L,va_arg(vl,double));break;}
			case 'p':{lua_pushlightuserdata(L,va_arg(vl,void*));break;}
			case 'r':{
				luaRef_t ref = va_arg(vl,luaRef_t);
				lua_rawgeti(L,LUA_REGISTRYINDEX,ref.rindex);
				break;
			}
			default:{
				snprintf(lua_errmsg,4096,"invaild operation(%c)",fmt[k]);
				errmsg = lua_errmsg;
				goto end;	
			}
		}
		//set table
		lua_settable(L,-3);		
	}								
end:
	lua_settop(L,oldtop);
	va_end(vl);
	return errmsg;
}
