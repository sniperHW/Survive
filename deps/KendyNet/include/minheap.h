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
#ifndef _MINHEAP_H
#define _MINHEAP_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

struct heapele
{
	int32_t index;//index in minheap;
};

typedef struct minheap
{
	int32_t size;
	int32_t max_size;
	int8_t (*less)(struct heapele*l,struct heapele*r);//if l < r return 1,else return 0	
	struct heapele** data;
}*minheap_t;


minheap_t minheap_create(int32_t size,int8_t (*)(struct heapele*l,struct heapele*r));
void minheap_destroy(minheap_t*);
typedef void (*clear_fun)(struct heapele*);
void minheap_clear(minheap_t,clear_fun);

static inline void minheap_swap(minheap_t m,int32_t idx1,int32_t idx2)
{
	struct heapele *ele = m->data[idx1];
	m->data[idx1] = m->data[idx2];
	m->data[idx2] = ele;
	m->data[idx1]->index = idx1;
	m->data[idx2]->index = idx2;
}

static inline int32_t parent(int32_t idx){
	return idx/2;
}

static inline int32_t left(int32_t idx){
	return idx*2;
}

static inline int32_t right(int32_t idx){
	return idx*2+1;
}

static inline void up(minheap_t m,int32_t idx){
	int32_t p = parent(idx);
	while(p)
	{
		assert(m->data[idx]);
		assert(m->data[p]);
		if(m->less(m->data[idx],m->data[p]))
		{
			minheap_swap(m,idx,p);
			idx = p;
			p = parent(idx);
		}
		else
			break;
	}
}

static inline void down(minheap_t m,int32_t idx){

	int32_t l = left(idx);
	int32_t r = right(idx);
	int32_t min = idx;
	if(l <= m->size)
	{
		assert(m->data[l]);
		assert(m->data[idx]);
	}

	if(l <= m->size && m->less(m->data[l],m->data[idx]))
		min = l;

	if(r <= m->size)
	{
		assert(m->data[r]);
		assert(m->data[min]);
	}

	if(r <= m->size && m->less(m->data[r],m->data[min]))
		min = r;

	if(min != idx)
	{
		minheap_swap(m,idx,min);
		down(m,min);
	}		
}

static inline void minheap_change(minheap_t m,struct heapele *e)
{
	int idx = e->index;
	down(m,idx);
	if(idx == e->index)
		up(m,idx);
}

static inline void minheap_insert(minheap_t m,struct heapele *e)
{
	if(e->index)
		return minheap_change(m,e);
	if(m->size >= m->max_size-1)
	{
		//expand the heap
		uint32_t new_size = m->max_size*2;
		struct heapele** tmp = (struct heapele**)calloc(new_size,sizeof(struct heapele*));
		if(!tmp)
			return;
		memcpy(tmp,m->data,m->max_size*sizeof(struct heapele*));
		free(m->data);
		m->data = tmp;
		m->max_size = new_size;
	}	
	++m->size;
	m->data[m->size] = e;
	e->index = m->size;
	up(m,e->index);	
}
/*
#include <stdio.h>
static inline void minheap_remove(minheap_t m,struct heapele *e)
{
	struct heapele **back = calloc(1,sizeof(struct heapele*)*(m->size-1));
	int32_t i = 1;
	int32_t c = 1;
	if(m->size == 5) 
		printf("here");
	for( ; i <= m->size;++i)
	{
		m->data[i]->index = 0;
		if(m->data[i] != e)
			back[c++] = m->data[i];
	}
	memset(&(m->data[0]),0,sizeof(struct heapele*)*m->max_size);
	m->size = 0;
	i = 1;
	for(; i < c; ++i)
		minheap_insert(m,back[i]);
	free(back);
}
*/


//return the min element
static inline struct heapele* minheap_min(minheap_t m)
{
	if(!m->size)
		return NULL;
	return m->data[1];
}

//return the min element and remove it
static inline struct heapele* minheap_popmin(minheap_t m)
{
	if(m->size)
	{
		struct heapele *e = m->data[1];
		minheap_swap(m,1,m->size);
		m->data[m->size] = NULL;
		--m->size;
		down(m,1);
		e->index = 0;
		return e;
	}
	return NULL;
}
#endif
