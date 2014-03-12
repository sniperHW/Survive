#include "map.h"
#include <math.h>
#include <assert.h>
#include "game/astar.h"
#include "game/aoi.h"

enum{
	BLOCK = 65536,
	LAND  = 5,   //平地
	SWAMP = 15,  //沼泽
	WATER = 50,  //水域
};

struct map;
struct node
{
	struct map_node _base;
	struct map      *_map;
	uint16_t         weights;
	int    x; 
	int    y;	
};

struct map
{
	struct node **_map;
	int    max_x;
	int    max_y;
};

int direction[8][2] = {
	{0,-1},//上
	{0,1},//下
	{-1,0},//左
	{1,0},//右
	{-1,-1},//左上
	{1,-1},//右上
	{-1,1},//左下
	{1,1},//右下
};

static  inline struct node *get_node_by_xy(struct map *map,int x,int y)
{
	if(x < 0 || x >= map->max_x || y < 0 || y >= map->max_y)
		return NULL;
	return map->_map[y*map->max_x+x];
}

//获得当前node的8个临近节点,如果是阻挡点会被忽略
static struct map_node** _get_neighbors(struct map_node *mnode)
{
	struct map_node **ret = (struct map_node **)calloc(9,sizeof(*ret));
	struct node *_node = (struct node*)mnode;
	struct map *_map = _node->_map;
	int32_t i = 0;
	int32_t c = 0;
	for( ; i < 8; ++i)
	{
		int x = _node->x + direction[i][0];
		int y = _node->y + direction[i][1];
		struct node *tmp = get_node_by_xy(_map,x,y);
		if(tmp && tmp->weights != BLOCK)
			ret[c++] = (struct map_node*)tmp;
	}
	ret[c] = NULL;
	return ret;
}
//计算到达相临节点需要的代价
static double _cost_2_neighbor(struct path_node *from,struct path_node *to)
{
	double cost;
	int delta_x = ((struct node*)from)->x - ((struct node*)to)->x;
	int delta_y = ((struct node*)from)->y - ((struct node*)to)->y;
	if(abs(delta_x) > 1 && abs(delta_y) > 1){
		//斜向
		cost = (double)((struct node*)to)->weights;
		cost *= 1.25f;		
	}else
		cost = (double)((struct node*)to)->weights; 
	return cost;
}

//用平地路径做估算值
static double _cost_2_goal(struct path_node *from,struct path_node *to)
{
	int delta_x = abs(((struct node*)from)->x - ((struct node*)to)->x);
	int delta_y = abs(((struct node*)from)->y - ((struct node*)to)->y);
	return (delta_x * LAND) + (delta_y * LAND);
}

struct map* create_map(uint16_t *array,int max_x,int max_y)
{
	struct map *_map = calloc(1,sizeof(*_map));
	_map->max_x = max_x;
	_map->max_y = max_y;
	_map->_map = (struct node**)calloc(max_x*max_y,sizeof(struct node*));
	int i = 0;
	int j = 0;
	for( ; i < max_y; ++i)
	{
		for(j = 0; j < max_x;++j)
		{		
			_map->_map[i*max_x+j] = calloc(1,sizeof(struct node));
			struct node *tmp = _map->_map[i*max_x+j];
			tmp->_map = _map;
			tmp->x = j;
			tmp->y = i;
			tmp->weights = array[i*max_x+j];			
		}
	}
	return _map;
}

void destroy_map(struct map **map)
{
	free((*map)->_map);
	free(*map);
}

//只用最简单的网格判断，再视野网格内的对象都认为是进入范围
static uint8_t in_myscope(struct aoi_object *self,struct aoi_object *other)
{
	return 1;
}
	
static void cb_enter(struct aoi_object *self,struct aoi_object *other)
{
	luaObject_t lua_self = (luaObject_t)self->ud;
	luaObject_t lua_other = (luaObject_t)other->ud;
	assert(lua_self->L == lua_other->L);
	CALL_OBJ_FUNC1(lua_self,"EnterView",0,PUSH_LUAOBJECT(lua_self->L,lua_other));
}
	
static void cb_leave(struct aoi_object *self,struct aoi_object *other)
{
	luaObject_t lua_self = (luaObject_t)self->ud;
	luaObject_t lua_other = (luaObject_t)other->ud;
	assert(lua_self->L == lua_other->L);
	CALL_OBJ_FUNC1(lua_self,"LeaveView",0,PUSH_LUAOBJECT(lua_self->L,lua_other));	
}

//一个战场地图实例
struct battlemap
{
	struct map *map;
	struct A_star_procedure *astar;
	struct aoi_map *aoi;
};

rbtree_t g_mapdefine;

int32_t fn_compare(void *l,void *r)
{
	return strcmp(to_cstr((string_t)l),to_cstr((string_t)r));
}

struct mapdefine *get_mapdefine(string_t mapname){
	return (struct mapdefine*)rbtree_find(g_mapdefine,mapname);
}


int luaNewBattleMap(lua_State *L){
	string_t mapname = new_string(lua_tostring(L,-1));
	struct mapdefine *def = get_mapdefine(mapname);
	if(def){
		struct battlemap *map = calloc(1,sizeof(*map));
		map->map = def->map;
		map->aoi = aoi_create(512,def->length,def->radius,&def->top_left,&def->bottom_right);
		map->astar = create_astar(_get_neighbors,_cost_2_neighbor,_cost_2_goal);
		PUSH_LUSRDATA(L,map);
	}else
		PUSH_NIL(L);
	return 1;
}

int luaDelBattleMap(lua_State *L){
	return 0;
}

//获取从源到目标的一条路径，如果不能通达返回空表，否则返回一条路径表
int luaGetPath(lua_State *L){	
	struct battlemap *battlemap = (struct battlemap *)lua_touserdata(L,-1);
	int to_x = (int)lua_tonumber(L,-2);
	int to_y = (int)lua_tonumber(L,-3);
	int from_x = (int)lua_tonumber(L,-4);
	int from_y = (int)lua_tonumber(L,-5);
	
	struct map_node *from = (struct map_node*)get_node_by_xy(battlemap->map,from_x,from_y);
	struct map_node *to = (struct map_node*)get_node_by_xy(battlemap->map,to_x,to_y);
	struct path_node *path = find_path(battlemap->astar,from,to);
	if(!path)
	{
		PUSH_NIL(L);
		return 1;
	}
	lua_newtable(L);
	int i = 1;
	while(path)
	{
		struct node *mnode = (struct node*)path->_map_node;
		PUSH_TABLE2(L,lua_pushnumber(L,mnode->x),lua_pushnumber(L,mnode->y));
		lua_rawseti(L,-2,i++);		
		path = path->parent;
	}	
	return 1;
}

int luaAoiEnterMap(lua_State *L){
	struct battlemap *battlemap = (struct battlemap*)lua_touserdata(L,-1);
	luaObject_t self = create_luaObj(L,-2);
	int x = (int)lua_tonumber(L,-3);
	int y = (int)lua_tonumber(L,-4);	
	struct aoi_object *aoi_obj = calloc(1,sizeof(*aoi_obj));
	aoi_obj->ud = self;
	aoi_obj->in_myscope = in_myscope;
	aoi_obj->cb_enter = cb_enter;
	aoi_obj->cb_leave = cb_leave;
	
	if(0 == aoi_enter(battlemap->aoi,aoi_obj,x,y)){
		PUSH_LUSRDATA(L,aoi_obj);
	}else
	{
		free(aoi_obj);
		PUSH_NIL(L);
	}
	return 1;
}

int luaAoiLeaveMap(lua_State *L){
	struct battlemap *battlemap = (struct battlemap*)lua_touserdata(L,-1);	
	struct aoi_object *aoi_obj = lua_touserdata(L,-2);
	if(0 == aoi_leave(battlemap->aoi,aoi_obj)){
		release_luaObj((luaObject_t)aoi_obj->ud);
		free(aoi_obj);
		PUSH_BOOL(L,1);
	}else
		PUSH_BOOL(L,0);
	return 1;
}

int luaAoiMoveTo(lua_State *L){
	struct battlemap *battlemap = (struct battlemap*)lua_touserdata(L,-1);	
	struct aoi_object *aoi_obj = lua_touserdata(L,-2);
	int x = (int)lua_tonumber(L,-3);
	int y = (int)lua_tonumber(L,-4);
	aoi_moveto(battlemap->aoi,aoi_obj,x,y);
	return 0;
}

void map_register2lua(lua_State *L)
{
	lua_register(L,"NewBattleMap",&luaNewBattleMap);
	lua_register(L,"DelBattleMap",&luaDelBattleMap);
	lua_register(L,"GetPath",&luaGetPath);
	lua_register(L,"AoiEnterMap",&luaAoiEnterMap);
	lua_register(L,"AoiLeaveMap",&luaAoiLeaveMap);
	lua_register(L,"AoiMoveTo",&luaAoiMoveTo);	
}

void map_init(){
	
}
