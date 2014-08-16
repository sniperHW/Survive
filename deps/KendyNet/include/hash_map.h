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
#ifndef _HASH_MAP_H
#define _HASH_MAP_H
#include <stdint.h>
#include "common_hash_function.h"
#include "kn_dlist.h"


typedef struct{
	kn_dlist_node node;
	uint64_t hash_code;
	uint64_t snd_hash_code;
	int8_t   flag;
	void    *key;
}hash_node; 


typedef uint64_t (*hash_func)(void*);
typedef void     (*hash_destroy)(hash_node*);
typedef int      (*key_cmp)(void*,void*); 


#define SLOT_CAP 8

typedef struct{
	int        size;	
	hash_node *nodes[SLOT_CAP];
}hash_slot;

typedef struct hash_map
{
	hash_func          hash_function;
	hash_func          snd_hash_function;
	key_cmp            key_cmp_function;
	uint32_t           slot_size;
	uint32_t           size;
	kn_dlist           dlink;
	hash_slot         *slots; 
}*hash_map_t;

/*
 * snd_hash可以为NULL,但是建议添加一个与hash不同的snd_hash函数以减少cmp的调用次数
*/
hash_map_t     hash_map_create(uint32_t slot_size,hash_func hash,key_cmp cmp,hash_func snd_hash);

void           hash_map_destroy(hash_map_t,hash_destroy ondestroy);
int            hash_map_insert(hash_map_t,hash_node*);
hash_node*     hash_map_remove(hash_map_t,void *key);
hash_node*     hash_map_find(hash_map_t,void* key); 


#define for_each(h,type,cur) for(cur=(type)h->dlink.head.next; (kn_dlist_node*)cur != &h->dlink.tail; cur = (type)((kn_dlist_node*)cur)->next)



#endif
