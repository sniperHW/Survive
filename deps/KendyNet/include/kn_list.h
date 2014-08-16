/*
    Copyright (C) <2014>  <huangweilook@21cn.com>

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
/*
 *单向链表
*/
#ifndef _KN_LIST_H
#define _KN_LIST_H

#include <stdint.h>
#include <stdlib.h>

typedef struct kn_list_node
{
    struct kn_list_node *next;
}kn_list_node;


typedef struct kn_list
{
	int32_t        size;
    kn_list_node*  head;
    kn_list_node*  tail;
}kn_list;

static inline void kn_list_init(kn_list *l){
	l->head = l->tail = NULL;
	l->size = 0;
}

static inline kn_list_node* kn_list_head(kn_list *l)
{
	return l->head;
}

static inline kn_list_node* kn_list_tail(kn_list *l)
{
	return l->tail;
}


static inline void kn_list_pushback(kn_list *l,kn_list_node *n)
{
    if(n->next) return;
	n->next = NULL;
	if(0 == l->size)
		l->head = l->tail = n;
	else
	{
		l->tail->next = n;
		l->tail = n;
	}
	++l->size;
}

static inline void kn_list_pushfront(kn_list*l,kn_list_node *n)
{
    if(n->next) return;
	n->next = NULL;
	if(0 == l->size)
		l->head = l->tail = n;
	else
	{
		n->next = l->head;
		l->head = n;
	}
	++l->size;
}

static inline kn_list_node* kn_list_pop(kn_list *l)
{
	kn_list_node *ret = NULL;
	if(0 == l->size)
		return ret;
    ret = l->head;
	l->head = l->head->next;
	if(NULL == l->head)
		l->tail = NULL;
	--l->size;
	ret->next = NULL;
	return ret;
}

static inline int32_t kn_list_size(kn_list *l)
{
	return l->size;
}

static inline void kn_list_swap(kn_list *to,kn_list *from)
{
	if(from->head && from->tail)
	{
		if(to->tail)
			to->tail->next = from->head;
		else
			to->head = from->head;
		to->tail = from ->tail;
		from->head = from->tail = NULL;
		to->size += from->size;
		from->size = 0;
	}
}

#endif
