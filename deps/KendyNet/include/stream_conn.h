#ifndef _STREAM_CONN_H
#define _STREAM_CONN_H

//面向数据流的连接
#include "kendynet.h"
#include "packet.h"
#include "rpacket.h"
#include "wpacket.h"
#include "rawpacket.h"
#include "kn_refobj.h"
#include "kn_timer.h"

#define MAX_WBAF 512
#define MAX_SEND_SIZE 65535

typedef struct stream_conn
{
	refobj   refobj;	
	handle_t handle;
	struct   iovec wsendbuf[MAX_WBAF];
	struct   iovec wrecvbuf[2];
	st_io    send_overlap;
	st_io    recv_overlap;
	void*    ud;
	uint32_t unpack_size; //还未解包的数据大小
	uint32_t unpack_pos;
	uint32_t next_recv_pos;
	buffer_t next_recv_buf;
	buffer_t unpack_buf;
	kn_list  send_list;//待发送的包
	uint8_t  doing_send;
	uint32_t recv_bufsize;
	uint8_t  is_close;
	int      (*on_packet)(struct stream_conn*,packet_t);
	void     (*on_disconnected)(struct stream_conn*,int err);
	uint8_t  packet_type;
	uint8_t  processing;
	kn_timer_t sendtimer; 
}stream_conn,*stream_conn_t;

/*
 *   返回1：process_packet调用后rpacket_t自动销毁
 *   否则,将由使用者自己销毁
 */
typedef int  (*CCB_PROCESS_PKT)(stream_conn_t,packet_t);
typedef void (*CCB_DISCONNECTD)(stream_conn_t,int err);

/*packet_type:RPACKET/RAWPACKET*/
stream_conn_t new_stream_conn(handle_t sock,uint32_t buffersize,uint8_t packet_type);
void     stream_conn_close(stream_conn_t c);
int      stream_conn_send(stream_conn_t c,packet_t p);
static inline handle_t stream_conn_gethandle(stream_conn_t c){
	return c->handle;
} 

static inline void stream_conn_setud(stream_conn_t c,void *ud){
	c->ud = ud;
}
static inline void* stream_conn_getud(stream_conn_t c){
	return c->ud;
}
/*
 * 与engine关联并启动接收过程.
 * 如果conn已经关联过,则首先与原engine断开关联.
 * 如果engine为NULL，则断开关联
 *  
*/
int     stream_conn_associate(engine_t,stream_conn_t conn,CCB_PROCESS_PKT,CCB_DISCONNECTD);



#endif
