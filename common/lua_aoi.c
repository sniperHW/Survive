#include <stdio.h>
#include <string.h>
#include "lua_util.h"
#include "aoi.h"

static uint8_t in_myscope(aoi_object *_self,aoi_object *_other){
	/*luaObject_t self = (luaObject_t)_self->ud;
	luaObject_t other = (luaObject_t)_other->ud;
	lua_State *L = self->L;
	const char *error = NULL;
	if((error = CALL_OBJ_FUNC1(self,"isInMyScope",1,
					  PUSH_LUAOBJECT(L,other)))){
		LOG_GAME(LOG_INFO,"error on enter_see:%s\n",error);
		return 0;
	}
	return lua_tonumber(L,1);*/
	return 1;		
}

static void    cb_enter(aoi_object *_self,aoi_object *_other){
	luaRef_t* self = (luaRef_t*)_self->ud;
	luaRef_t* other = (luaRef_t*)_other->ud;
	const char *error;	
	if((error = LuaCallTabFuncS(*self,"enter_see","r",*other))){
		printf("aoi error enter_see:%s\n",error);			
	}			
}

static void    cb_leave(aoi_object *_self,aoi_object *_other){
	luaRef_t* self = (luaRef_t*)_self->ud;
	luaRef_t* other = (luaRef_t*)_other->ud;
	const char *error;
	if((error = LuaCallTabFuncS(*self,"leave_see","r",*other))){
		printf("aoi error enter_see:%s\n",error);			
	}					
}

static int lua_create_aoi_obj(lua_State *L){
	luaRef_t *obj = calloc(1,sizeof(*obj));	
	*obj = toluaRef(L,1);
	aoi_object* o = calloc(1,sizeof(*o));
	o->in_myscope = in_myscope;
	o->cb_enter = cb_enter;
	o->cb_leave = cb_leave;
	o->ud = obj;
	o->view_objs = new_bitset(4096);
	lua_pushlightuserdata(L,o);
	return 1;
}

static int lua_destroy_aoi_obj(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	if(o->map) aoi_leave(o);
	del_bitset(o->view_objs);
	release_luaRef((luaRef_t*)o->ud);
	free(o->ud);
	free(o);
	return 0;
}

static int lua_create_aoimap(lua_State *L){
	uint32_t length = lua_tonumber(L,1);
	uint32_t radius = lua_tonumber(L,2);
	point2D  top_left,bottom_right;
	top_left.x = lua_tonumber(L,3);
	top_left.y = lua_tonumber(L,4);
	bottom_right.x = lua_tonumber(L,5);
	bottom_right.y = lua_tonumber(L,6);	
	aoi_map *m = aoi_create(4096,length,radius,&top_left,&bottom_right);
	lua_pushlightuserdata(L,(void*)m);
	return 1;
}

static int lua_destroy_aoimap(lua_State *L){
	aoi_map *m = lua_touserdata(L,1);
	aoi_destroy(m);
	return 0;
}

static int lua_aoi_enter(lua_State *L){
	aoi_map   * m = lua_touserdata(L,1);
	aoi_object* o = lua_touserdata(L,2);
	int x = (int)lua_tonumber(L,3);
	int y = (int)lua_tonumber(L,4);
	
	if(0 == aoi_enter(m,o,x,y))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;	
}

static int lua_aoi_leave(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	
	if(0 == aoi_leave(o))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;		
}

static int lua_aoi_moveto(lua_State *L){
	aoi_object* o = lua_touserdata(L,1);
	int x = (int)lua_tonumber(L,2);
	int y = (int)lua_tonumber(L,3);	
	if(0 == aoi_moveto(o,x,y))
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;			
}

int luaopen_aoi(lua_State *L) {
    luaL_Reg l[] = {
        {"create_map",lua_create_aoimap},
        {"destroy_map",lua_destroy_aoimap},
        {"create_obj",lua_create_aoi_obj},
        {"destroy_obj",lua_destroy_aoi_obj},
        {"enter_map",lua_aoi_enter},    
        {"leave_map",lua_aoi_leave},
        {"moveto",lua_aoi_moveto},                                             
        {NULL, NULL}
    };
    luaL_newlib(L, l);
    return 1;
}


