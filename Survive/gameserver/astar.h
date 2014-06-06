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
#include <stdint.h>
#include <stdlib.h>
#include "dlist.h"
#include "llist.h"
#include "hash_map.h"
#include "minheap.h"

//一个地图块节点
struct map_node{};

//路径节点
struct path_node
{	
	struct heapele _heapele;	
	struct dnode _close_list_node;
	struct path_node *parent;
	struct map_node  *_map_node;
	double G;//从初始点到当前点的开销
	double H;//从当前点到目标点的估计开销
	double F;
};

//由使用者提供的3个函数
//get_neighbors约定:如果一个map_node*是阻挡点,将不会被返回
typedef struct map_node** (*get_neighbors)(struct map_node*);
typedef double (*cost_2_neighbor)(struct path_node*,struct path_node*);
typedef double (*cost_2_goal)(struct path_node*,struct path_node*);

//一次路径搜索的过程对象
struct A_star_procedure
{
	get_neighbors _get_neighbors;
	cost_2_neighbor _cost_2_neighbor;//用于计算两个路径点G值的函数指针
	cost_2_goal _cost_2_goal;//用于计算两个路径点H值的函数指针
	minheap_t open_list;
	struct dlist close_list;
	hash_map_t mnode_2_pnode;//map_node到path_node的映射
};

struct A_star_procedure *create_astar(get_neighbors,cost_2_neighbor,cost_2_goal);
//寻找从from到to的路径,找到返回路径点,否则返回NULL
struct path_node* find_path(struct A_star_procedure *astar,struct map_node *from,struct map_node *to);
void   destroy_Astar(struct A_star_procedure**);
