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

#ifndef _BUFFER_H
#define _BUFFER_H

/*
* 带引用计数的buffer
*/

#include <stdint.h>
#include <string.h>
#include "kn_refobj.h"
#include "kn_list.h"

extern uint32_t buffer_count;

typedef struct buffer
{
	refobj    refboj;
	uint32_t  capacity;
	uint32_t  size;
	struct buffer *next;
	int8_t   buf[0];
}*buffer_t;



static inline void buffer_release(buffer_t b)
{
	if(b){
		refobj_dec((refobj*)b);
	}
}

static void buffer_destroctor(void *b)
{
	buffer_t _b = (buffer_t)b;
	if(_b->next)
		buffer_release((_b)->next);
    free(_b);
    --buffer_count;
}

static inline buffer_t buffer_create(uint32_t capacity)
{
	uint32_t size = sizeof(struct buffer) + capacity;
    buffer_t b = (buffer_t)calloc(1,size);
	if(b)
	{
		b->size = 0;
		b->capacity = capacity;
		refobj_init((refobj*)b,buffer_destroctor);
		++buffer_count;
	}
	return b;
}


static inline buffer_t buffer_acquire(buffer_t b1,buffer_t b2)
{
    if(b1 == b2) return b1;
    if(b2) refobj_inc((refobj*)b2);
    if(b1) refobj_dec((refobj*)b1);
	return b2;
}

/*
* 从b的pos开始读取size字节长的数据,如果长度大于b->size-pos,会尝试从b->next中读出剩余部分
*/

static inline int buffer_read(buffer_t b,uint32_t pos,int8_t *out,uint32_t size)
{
	uint32_t copy_size;
	while(size){
        if(!b) return -1;
        if(pos >= b->size) return -1;
        copy_size = b->size - pos;
		copy_size = copy_size > size ? size : copy_size;
		memcpy(out,b->buf + pos,copy_size);
		size -= copy_size;
		pos += copy_size;
		out += copy_size;
		if(pos >= b->size){
			pos = 0;
			b = b->next;
		}
	}
	return 0;
}


/*
*将长度为size字节的数据写入到b的pos开始位置，如果size大于b->capacity-pos,会尝试将剩余部分写入到
*b->next中
*/
static inline int buffer_write(buffer_t b,uint32_t pos,int8_t *in,uint32_t size)
{
    uint32_t copy_size;
    while(size){
        if(!b) return -1;
        if(pos >= b->capacity) return -1;
        copy_size = b->capacity - pos;
        copy_size = copy_size > size ? size : copy_size;
        memcpy(b->buf + pos,in,copy_size);
        size -= copy_size;
        pos += copy_size;
        in += copy_size;
        if(pos >= b->capacity){
            pos = 0;
            b = b->next;
        }
    }
    return 0;
}

#endif
