#ifndef _MAP_H
#define _MAP_H

#include "core/lua_util.h"
#include "core/rbtree.h"
#include "core/kn_string.h"
#include "core/point.h"

void map_register2lua(lua_State *L);

enum{
	map_battle = 1,//战场地图
	map_open = 2,  //开放地图
};

//地图定义
struct mapdefine
{
	struct rbnode rbnode;
	string_t   mapname;
	uint16_t   mapid;
	uint8_t    maptype;
	struct map *map;
	//以下字段由aoi使用
	uint32_t       length;
	uint32_t       radius;
    struct point2D top_left;
    struct point2D bottom_right;
};

//在进程启动时调,初始化地图配置信息
void map_init();

struct mapdefine *get_mapdefine_byid(uint16_t id);

//获得一个开放地图的实例，如果没有返回0
uint32_t get_openinstance_byid(uint16_t id);

#endif
