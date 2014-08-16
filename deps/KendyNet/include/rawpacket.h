#ifndef _RAWPACKET_H
#define _RAWPACKET_H

#include "packet.h"
#include "kn_common_define.h"

typedef struct rawpacket
{
	struct packet base;
}*rawpacket_t;

static inline rawpacket_t rawpacket_create1(buffer_t b,uint32_t pos,uint32_t len){
	if(!b) return NULL;
	rawpacket_t p = calloc(1,sizeof(*p));
	packet_buf(p) = buffer_acquire(NULL,b);
	packet_begpos(p) = pos;
	packet_type(p) = RAWPACKET;
	packet_datasize(p) = len;
	return p;
}

static inline rawpacket_t rawpacket_create2(void *ptr,uint32_t len){
	if(!ptr) return NULL;
    uint32_t size = size_of_pow2(len);
    if(size < 64) size = 64;
    buffer_t tmp = buffer_create(size);
    memcpy(tmp->buf,ptr,len);
    tmp->size = len;
	rawpacket_t p = calloc(1,sizeof(*p));    
    packet_buf(p) = tmp;
	packet_type(p) = RAWPACKET;    
	packet_datasize(p) = len;
    return p; 	
}

static inline rawpacket_t rawpacket_copy_create(rawpacket_t other){
	if(!other) return NULL;
	rawpacket_t p = calloc(1,sizeof(*p));
	packet_buf(p) = buffer_acquire(NULL,packet_buf(other));
	packet_begpos(p) = packet_begpos(other);
	packet_type(p) = RAWPACKET;	
	packet_datasize(p) = packet_datasize(other);
	return p;
}

static inline void* rawpacket_data(rawpacket_t p,uint32_t *len){
	if(!packet_buf(p)) return NULL;
	if(len) *len = packet_datasize(p);
	return &(packet_buf(p)->buf[packet_begpos(p)]);
}


#endif
