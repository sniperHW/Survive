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
#ifndef _RPACKET_H
#define _RPACKET_H

#include "packet.h"
#include "kn_common_define.h"

typedef struct rpacket
{
	struct packet base;
	uint32_t len;          //包长(去除包长度字段)
	uint32_t rpos;          //读下标
	uint32_t data_remain;
	uint32_t binbufpos;
	buffer_t binbuf;       //用于存放跨越buffer_t边界数据的buffer_t
	buffer_t readbuf;      //当前rpos所在的buffer_t
}*rpacket_t;

struct wpacket;

rpacket_t rpk_create(buffer_t,uint32_t pos,uint32_t pk_len);

rpacket_t rpk_copy_create(struct packet*);

//丢弃r最后dropsize字节的内容
void      rpk_dropback(rpacket_t r,uint32_t dropsize);

//通过另一个rpacket拷贝构造一个rpacket_t,丢弃前skipsize个字节
rpacket_t rpk_create_skip(rpacket_t other,uint32_t skipsize);


static inline buffer_t  rpk_readbuf(rpacket_t r)
{
    return r->readbuf;
}

static inline uint32_t  rpk_rpos(rpacket_t r)
{
    return r->rpos;
}

//数据读取接口
static inline uint32_t  rpk_len(rpacket_t r){
	return r->len;
}

static inline uint32_t rpk_data_remain(rpacket_t r){
	return r->data_remain;
}

static inline int rpk_read(rpacket_t r,int8_t *out,uint32_t size)
{
	if(unlikely(r->data_remain < size))
		return -1;

	while(likely(size>0))
	{
		uint32_t copy_size = r->readbuf->size - r->rpos;
		copy_size = copy_size >= size ? size:copy_size;
		memcpy(out,r->readbuf->buf + r->rpos,copy_size);
		size -= copy_size;
		r->rpos += copy_size;
		r->data_remain -= copy_size;
		out += copy_size;
		if(r->rpos >= r->readbuf->size && r->data_remain)
		{
			//当前buffer数据已经被读完,切换到下一个buffer
			r->rpos = 0;
			r->readbuf = buffer_acquire(r->readbuf,r->readbuf->next);
		}
	}
	return 0;
}

static inline int rpk_peek(rpacket_t r,int8_t *out,uint32_t size){
    if(unlikely(r->data_remain < size))
        return -1;
    buffer_t buffer = r->readbuf;
    uint32_t pos = r->rpos;
    uint32_t data_remain = r->data_remain;
    while(likely(size>0))
    {

        uint32_t copy_size = buffer->size - pos;
        copy_size = copy_size >= size ? size:copy_size;
        memcpy(out,buffer->buf + pos,copy_size);
        size -= copy_size;
        pos += copy_size;
        out += copy_size;
        data_remain -= copy_size;
        if(pos >= buffer->size && data_remain)
        {
            //当前buffer数据已经被读完,切换到下一个buffer
            pos = 0;
            buffer = buffer->next;
        }
    }
    return 0;
}

#define CHECK_READ(TYPE)\
		if(likely(r->readbuf->size - r->rpos >= sizeof(TYPE))){\
			uint32_t pos = r->rpos;\
			r->rpos += sizeof(TYPE);\
			r->data_remain -= sizeof(TYPE);\
			return *(TYPE*)(r->readbuf->buf+pos);\
		}

static inline uint8_t rpk_read_uint8(rpacket_t r)
{
	CHECK_READ(uint8_t);
	uint8_t value = 0;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;
}

static inline uint16_t rpk_read_uint16(rpacket_t r)
{
	CHECK_READ(uint16_t);
	uint16_t value = 0;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;
}

static inline uint32_t rpk_read_uint32(rpacket_t r)
{
	CHECK_READ(uint32_t);
	uint32_t value = 0;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;
}

static inline uint64_t rpk_read_uint64(rpacket_t r)
{
	CHECK_READ(uint64_t);
	uint64_t value = 0;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;
}

static inline double rpk_read_double(rpacket_t r)
{
	CHECK_READ(double);
	double value = 0;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;
}

static inline ident rpk_read_ident(rpacket_t r)
{
	CHECK_READ(ident);
	ident value;
	rpk_read(r,(int8_t*)&value,sizeof(value));
	return value;	
}


#define CHECK_PEEK(TYPE)\
		if(likely(r->readbuf->size - r->rpos >= sizeof(TYPE))){\
			return *(TYPE*)(r->readbuf->buf+r->rpos);\
		}

static inline uint16_t rpk_peek_uint16(rpacket_t r)
{
	CHECK_PEEK(uint16_t);
    uint16_t value = 0;
    rpk_peek(r,(int8_t*)&value,sizeof(value));
    return value;
}

const char*    rpk_read_string(rpacket_t);
const void*    rpk_read_binary(rpacket_t,uint32_t *len);

//以下函数可以读取包最尾部的数据
static inline int reverse_read(rpacket_t r,int8_t *out,uint32_t size)
{
    if(r->len < size)return -1;
    //首先要到正确的读位置
    uint32_t move_size = r->len - size + sizeof(r->len);

    buffer_t buf = ((packet*)r)->buf;
    uint32_t pos = ((packet*)r)->begin_pos;
    while(move_size){
        uint32_t s = buf->size - pos;
        if(s > move_size) s = move_size;
        move_size -= s;
        pos += s;
        if(pos >= buf->size){
            buf = buf->next;
            pos = 0;
        }
    }

    while(size>0)
    {
        uint32_t copy_size = buf->size - pos;
        copy_size = copy_size >= size ? size:copy_size;
        memcpy(out,buf->buf + pos,copy_size);
        size -= copy_size;
        out += copy_size;
		pos += copy_size;
        if(pos >= buf->size && size)
        {
            //当前buffer数据已经被读完,切换到下一个buffer
            pos = 0;
            buf = buf->next;
        }
    }
    return 0;
}

static inline uint8_t reverse_read_uint8(rpacket_t r)
{
    uint8_t value = 0;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

static inline uint16_t reverse_read_uint16(rpacket_t r)
{
    uint16_t value = 0;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

static inline uint32_t reverse_read_uint32(rpacket_t r)
{
    uint32_t value = 0;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

static inline uint64_t reverse_read_uint64(rpacket_t r)
{
    uint64_t value = 0;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

static inline double reverse_read_double(rpacket_t r)
{
    double value = 0;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

static inline ident reverse_read_ident(rpacket_t r)
{
    ident value;
    reverse_read(r,(int8_t*)&value,sizeof(value));
    return value;
}

#endif
