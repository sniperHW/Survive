#include "rpacket.h"
#include "wpacket.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "kn_common_define.h"
#include "kn_atomic.h"


rpacket_t rpk_create(buffer_t b,
                     uint32_t pos,
                     uint32_t pk_len)
{
	rpacket_t r = (rpacket_t)calloc(1,sizeof(*r));
	r->binbuf = NULL;
	r->binbufpos = 0;
	packet_buf(r) = buffer_acquire(NULL,b);
	r->readbuf = buffer_acquire(NULL,b);
	r->len = pk_len;
	r->data_remain = r->len;
	packet_begpos(r) = pos;
	packet_next(r) = NULL;
	packet_type(r) = RPACKET;
	r->rpos = (pos + sizeof(r->len))%packet_buf(r)->capacity;
	if(r->rpos < packet_begpos(r))
		r->readbuf = buffer_acquire(r->readbuf,r->readbuf->next);
	return r;
}

static inline rpacket_t rpk_create_by_rpacket(rpacket_t other)
{
	rpacket_t r = (rpacket_t)calloc(1,sizeof(*r));
    r->binbuf = NULL;
	r->binbufpos = 0;
    packet_buf(r) = buffer_acquire(NULL,packet_buf(other));
	r->readbuf = buffer_acquire(NULL,other->readbuf);
	r->len = other->len;
    r->data_remain = other->data_remain;
    packet_begpos(r) = packet_begpos(other);
    packet_next(r) = NULL;
    packet_type(r) = RPACKET;
	r->rpos = other->rpos;
	return r;
}

static inline rpacket_t rpk_create_by_wpacket(struct wpacket *w)
{
	rpacket_t r = (rpacket_t)calloc(1,sizeof(*r));
	r->binbuf = NULL;
	r->binbufpos = 0;
    packet_buf(r) = buffer_acquire(NULL,packet_buf(w));
    r->readbuf = buffer_acquire(NULL,packet_buf(w));
    packet_begpos(r) = packet_begpos(w);
    packet_next(r) = NULL;
    packet_type(r) = RPACKET;

	//这里的len只记录构造时wpacket的len,之后wpacket的写入不会影响到rpacket的len
	r->len = packet_datasize(w) - sizeof(r->len);
	r->rpos = (packet_begpos(r) + sizeof(r->len))%packet_buf(r)->capacity;
	if(r->rpos < packet_begpos(r))//base->begin_pos)
		r->readbuf = buffer_acquire(r->readbuf,r->readbuf->next);

	r->data_remain = r->len;
	return r;
}

rpacket_t rpk_copy_create(struct packet *p)
{
    if(packet_type(p) == RPACKET)
		return rpk_create_by_rpacket((rpacket_t)p);
    else if(packet_type(p) == WPACKET)
		return rpk_create_by_wpacket((wpacket_t)p);
	return NULL;
}

void rpk_dropback(rpacket_t r,uint32_t dropsize)
{
    if(!r || r->len < dropsize)
        return;
    r->len -= dropsize;
    if(r->data_remain > dropsize)
        r->data_remain -= dropsize;
    else
        r->data_remain = 0;
    buffer_write(packet_buf(r),packet_begpos(r),(int8_t*)&r->len,sizeof(r->len));
}


rpacket_t rpk_create_skip(rpacket_t other,uint32_t skipsize)
{
    if(!other || other->len <= skipsize)
        return NULL;
    rpacket_t r = (rpacket_t)calloc(1,sizeof(*r));
    //首先要到正确的读位置
    uint32_t move_size = skipsize+sizeof(r->len);
    buffer_t buf = packet_buf(other);
    uint32_t pos = packet_begpos(other);
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

    r->binbuf = NULL;
    r->binbufpos = 0;
    packet_buf(r) = buffer_acquire(NULL,buf);
    r->readbuf = buffer_acquire(NULL,buf);
    r->len = other->len-skipsize;
    r->data_remain = r->len;
    r->rpos = packet_begpos(r) = pos;
    packet_next(r) = NULL;
    packet_type(r) = RPACKET;
    return r;
}

const char* rpk_read_string(rpacket_t r)
{
	uint32_t len = 0;
	return (const char *)rpk_read_binary(r,&len);
}

const void* rpk_read_binary(rpacket_t r,uint32_t *len)
{
	void *addr = 0;
	uint32_t size = 0;
	size = rpk_read_uint32(r);
	*len = size;
	if(!r->data_remain || r->data_remain < size)
		return addr;
	if(r->readbuf->size - r->rpos >= size)
	{
		addr = &r->readbuf->buf[r->rpos];
		r->rpos += size;
		r->data_remain -= size;
		if(r->rpos >= r->readbuf->size && r->data_remain)
		{
			//当前buffer数据已经被读完,切换到下一个buffer
			r->rpos = 0;
			r->readbuf = buffer_acquire(r->readbuf,r->readbuf->next);
		}
	}
	else
	{
		//数据跨越了buffer边界,创建binbuf,将数据拷贝到binbuf中
		if(!r->binbuf)
		{
			r->binbufpos = 0;
			r->binbuf = buffer_create(r->len);
		}
		addr = r->binbuf->buf + r->binbufpos;
		while(size)
		{
			uint32_t copy_size = r->readbuf->size - r->rpos;
			copy_size = copy_size >= size ? size:copy_size;
			memcpy(r->binbuf->buf + r->binbufpos,r->readbuf->buf + r->rpos,copy_size);
			size -= copy_size;
			r->rpos += copy_size;
			r->data_remain -= copy_size;
			r->binbufpos += copy_size;
			if(r->rpos >= r->readbuf->size && r->data_remain)
			{
				//当前buffer数据已经被读完,切换到下一个buffer
				r->rpos = 0;
				r->readbuf = buffer_acquire(r->readbuf,r->readbuf->next);
			}
		}

	}
	return addr;
}
