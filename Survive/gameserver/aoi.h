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
#ifndef _AOI_H
#define _AOI_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "kn_dlist.h"
#include "bitset.h"
#include "point.h"
#include "idmgr.h"


//地图网格管理单元
typedef struct 
{
	kn_dlist aoi_objs;//处于本网格的所有aoi对象
	uint32_t x;
	uint32_t y;
	uint32_t index;
}aoi_block;

struct aoi_map;
//aoi对象
typedef struct aoi_object
{
	kn_dlist_node       node;                  
	int32_t             id; 
	bit_set_t           view_objs;//在当前对象视野内的对象位图      
	point2D             pos;     
	void*               ud;
	struct aoi_map*     map;
	//使用者提供的函数，用于判断other是否在self的可视范围之内
	uint8_t (*in_myscope)(struct aoi_object *self,struct aoi_object *other);
	//other进入self视野之后的回调函数
	void    (*cb_enter)(struct aoi_object *self,struct aoi_object *other);
	//other离开self视野之后的回调函数
	void    (*cb_leave)(struct aoi_object *self,struct aoi_object *other);
}aoi_object;



typedef struct aoi_map{
	//以下7个成员用于移动时做集合运算
	bit_set_t        new_block_set;
	bit_set_t        old_block_set;
	aoi_block**      new_blocks;
	aoi_block**      old_blocks;
	aoi_block**      enter_blocks;   //一次移动进入的管理单元
	aoi_block**      unchange_blocks;//一次移动没有变化的管理单元
	aoi_block**      leave_blocks;   //一次移动离开的管理单元
	
	//左上角，右下角坐标
	point2D          top_left;
	point2D          bottom_right;
	
	uint32_t         x_size; //横向管理单元格数量
	uint32_t         y_size; //纵向管理单元格数量
	
	uint32_t         radius; //视距
	uint32_t         max_aoi_objs;//地图中能容纳的最大aoi对象数量
	idmgr_t          _idmgr;
	aoi_block        blocks[];	
}aoi_map;


aoi_map *aoi_create(uint32_t max_aoi_objs,uint32_t _length,uint32_t radius,
					point2D *top_left,point2D *bottom_right);
					   
void    aoi_destroy(aoi_map*);

int32_t aoi_moveto(aoi_object *o,int32_t _x,int32_t _y);

int32_t aoi_enter(aoi_map *m,aoi_object *o,int32_t _x,int32_t _y);

int32_t aoi_leave(aoi_object *o);


#endif
