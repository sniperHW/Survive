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
#ifndef _ASTAR_H
#define _ASTAR_H
#include <stdint.h>
#include <stdlib.h>
#include "kn_dlist.h"
#include "minheap.h"

extern int direction[8][2];

#define BLOCK 0xFFFFFFFF

typedef struct AStarNode{
	kn_dlist_node     list_node;
	struct heapele    heap;
	struct AStarNode *parent;
	double G;      //从初始点到当前点的开销
	double H;      //从当前点到目标点的估计开销
	double F;
	int    x;
	int    y;
	int    value;	 
}AStarNode;

typedef struct{
	int          xcount;
	int          ycount;
	minheap_t    open_list;
	kn_dlist     close_list;
	kn_dlist     neighbors;
	AStarNode    map[0];
}AStar,*AStar_t;


AStar_t create_AStar(int xsize,int ysize,int *values);
int     find_path(AStar_t,int x,int y,int x1,int y1,kn_dlist *path);
#endif
