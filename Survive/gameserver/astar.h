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
#include "kn_dlist.h"
#include "minheap.h"
/*#include "dlist.h"
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
*/


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





/*
class AStar{
public:
	struct mapnode : public heapele,public dnode
	{
		mapnode *parent;
		double G;//从初始点到当前点的开销
		double H;//从当前点到目标点的估计开销
		double F;
		int    x;
		int    y;
		int    value;
	};

private:

	static bool _less(heapele*l,heapele*r)
	{
		return ((mapnode*)l)->F < ((mapnode*)r)->F;
	}

	static void _clear(heapele*e){
		((mapnode*)e)->F = ((mapnode*)e)->G = ((mapnode*)e)->H = 0;
	}

	mapnode *get_mapnode(int x,int y)
	{
		if(x < 0 || x >= m_xcount || y < 0 || y >= m_ycount)
			return NULL;
		return &m_map[y*m_xcount+x];
	}

	//获得当前maze_node的8个临近节点,如果是阻挡点会被忽略
	std::vector<mapnode*>* get_neighbors(mapnode *mnode)
	{
		m_neighbors.clear();
		int32_t i = 0;
		int32_t c = 0;
		for( ; i < 8; ++i)
		{
			int x = mnode->x + direction[i][0];
			int y = mnode->y + direction[i][1];
			mapnode *tmp = get_mapnode(x,y);
			if(tmp){
				if(tmp->value != 0xFFFFFFFF)
					m_neighbors.push_back(tmp);
			}
		}
		if(m_neighbors.empty()) return NULL;
		else return &m_neighbors;
	}

	//计算到达相临节点需要的代价
	double cost_2_neighbor(mapnode *from,mapnode *to)
	{
		int delta_x = from->x - to->x;
		int delta_y = from->y - to->y;
		int i = 0;
		for( ; i < 8; ++i)
		{
			if(direction[i][0] == delta_x && direction[i][1] == delta_y)
				break;
		}
		if(i < 4)
			return 50.0f;
		else if(i < 8)
			return 60.0f;
		else
		{
			assert(0);
			return 0.0f;
		}	
	}

	double cost_2_goal(mapnode *from,mapnode *to)
	{
		int delta_x = abs(from->x - to->x);
		int delta_y = abs(from->y - to->y);
		return (delta_x * 50.0f) + (delta_y * 50.0f);
	}

	void   reset();

	std::vector<mapnode*> m_neighbors;//中间计算用

	mapnode *m_map;
	int      m_xcount;
	int      m_ycount;
	minheap  open_list;
	dlist    close_list;
public:
	AStar():open_list(8192,_less,_clear){}

	bool Init(int x,int y,std::map<std::pair<int,int>,int> &values);

	~AStar(){
		if(m_map) free(m_map);
	}

	bool find_path(int x,int y,int x1,int y1,std::list<mapnode*> &path);
};
*/
