#include "stream_conn.h"
#include <assert.h>

static inline void update_next_recv_pos(stream_conn_t c,int32_t _bytestransfer)
{
	assert(_bytestransfer >= 0);
	uint32_t bytestransfer = (uint32_t)_bytestransfer;
	uint32_t size;
	do{
		size = c->next_recv_buf->capacity - c->next_recv_pos;
		size = size > bytestransfer ? bytestransfer:size;
		c->next_recv_buf->size += size;
		c->next_recv_pos += size;
		bytestransfer -= size;
		if(c->next_recv_pos >= c->next_recv_buf->capacity)
		{
			if(!c->next_recv_buf->next)
				c->next_recv_buf->next = buffer_create(c->recv_bufsize);
			c->next_recv_buf = buffer_acquire(c->next_recv_buf,c->next_recv_buf->next);
			c->next_recv_pos = 0;
		}
	}while(bytestransfer);
}

static inline int unpack(stream_conn_t c)
{
	uint32_t pk_len = 0;
	uint32_t pk_total_size;
	packet_t r = NULL;
	do{
		if(c->packet_type == RPACKET)
		{
			if(c->unpack_size <= sizeof(uint32_t))
				return 0;
			buffer_read(c->unpack_buf,c->unpack_pos,(int8_t*)&pk_len,sizeof(pk_len));
			pk_total_size = pk_len+sizeof(pk_len);
			if(pk_total_size > c->recv_bufsize){
				//可能是攻击
				return -1;
			}
			if(pk_total_size > c->unpack_size)
				return 0;
			r = (packet_t)rpk_create(c->unpack_buf,c->unpack_pos,pk_len);
			do{
				uint32_t size = c->unpack_buf->size - c->unpack_pos;
				size = pk_total_size > size ? size:pk_total_size;
				c->unpack_pos  += size;
				pk_total_size  -= size;
				c->unpack_size -= size;
				if(c->unpack_pos >= c->unpack_buf->capacity)
				{
					assert(c->unpack_buf->next);
					c->unpack_pos = 0;
					c->unpack_buf = buffer_acquire(c->unpack_buf,c->unpack_buf->next);
				}
			}while(pk_total_size);
		}
		else
		{
			pk_len = c->unpack_buf->size - c->unpack_pos;
			if(!pk_len) return 0;
			r = (packet_t)rawpacket_create1(c->unpack_buf,c->unpack_pos,pk_len);
			c->unpack_pos  += pk_len;
			c->unpack_size -= pk_len;
			if(c->unpack_pos >= c->unpack_buf->capacity)
			{
				assert(c->unpack_buf->next);
				c->unpack_pos = 0;
				c->unpack_buf = buffer_acquire(c->unpack_buf,c->unpack_buf->next);
			}
		}
		if(c->on_packet(c,r)) destroy_packet(r);
		if(c->is_close) return -2;
	}while(1);
	return 0;
}


static inline st_io *prepare_send(stream_conn_t c)
{
	int32_t i = 0;
	packet_t w = (packet_t)kn_list_head(&c->send_list);
	buffer_t b;
	uint32_t pos;
	st_io *O = NULL;
	uint32_t buffer_size = 0;
	uint32_t size = 0;
	uint32_t send_size_remain = MAX_SEND_SIZE;
	while(w && i < MAX_WBAF && send_size_remain > 0)
	{
		pos = packet_begpos(w);
		b = packet_buf(w);
		buffer_size = packet_datasize(w);
		while(i < MAX_WBAF && b && buffer_size && send_size_remain > 0)
		{
			c->wsendbuf[i].iov_base = b->buf + pos;
			size = b->size - pos;
			size = size > buffer_size ? buffer_size:size;
			size = size > send_size_remain ? send_size_remain:size;
			buffer_size -= size;
			send_size_remain -= size;
			c->wsendbuf[i].iov_len = size;
			++i;
			b = b->next;
			pos = 0;
		}
		if(send_size_remain > 0) w = (packet_t)packet_next(w);
	}
	if(i){
		c->send_overlap.iovec_count = i;
		c->send_overlap.iovec = c->wsendbuf;
		O = (st_io*)&c->send_overlap;
	}
	return O;

}
static inline void update_send_list(stream_conn_t c,int32_t _bytestransfer)
{
	assert(_bytestransfer >= 0);
	packet_t w;
	uint32_t bytestransfer = (uint32_t)_bytestransfer;
	uint32_t size;
	while(bytestransfer)
	{
		w = (packet_t)kn_list_pop(&c->send_list);
		assert(w);
		if((uint32_t)bytestransfer >= w->data_size)
		{
			bytestransfer -= w->data_size;
			destroy_packet(w);
		}
		else
		{
			while(bytestransfer)
			{
				size = packet_buf(w)->size - packet_begpos(w);
				size = size > (uint32_t)bytestransfer ? (uint32_t)bytestransfer:size;
				bytestransfer -= size;
				packet_begpos(w) += size;
				packet_datasize(w) -= size;
				if(packet_begpos(w) >= packet_buf(w)->size)
				{
					packet_begpos(w) = 0;
					packet_buf(w) = buffer_acquire(packet_buf(w),packet_buf(w)->next);
				}
			}
			kn_list_pushfront(&c->send_list,(kn_list_node*)w);
		}
	}
}

static void stream_conn_destroy(void *ptr)
{
	stream_conn_t c = (stream_conn_t)ptr;
	packet_t w;
	while((w = (packet_t)kn_list_pop(&c->send_list))!=NULL)
		destroy_packet(w);
	if(c->sendtimer) kn_del_timer(c->sendtimer);
	buffer_release(c->unpack_buf);
	buffer_release(c->next_recv_buf);
	kn_close_sock(c->handle);
	free(c);				
}

stream_conn_t new_stream_conn(handle_t sock,uint32_t buffersize,uint8_t packet_type)
{
	assert(packet_type == RPACKET || packet_type == RAWPACKET);
	buffersize = size_of_pow2(buffersize);
    if(buffersize < 1024) buffersize = 1024;	
	stream_conn_t c = calloc(1,sizeof(*c));
	c->packet_type = packet_type;
	c->recv_bufsize = buffersize;
	c->unpack_buf = buffer_create(buffersize);
	c->next_recv_buf = buffer_acquire(NULL,c->unpack_buf);
	c->wrecvbuf[0].iov_len = buffersize;
	c->wrecvbuf[0].iov_base = c->next_recv_buf->buf;
	c->recv_overlap.iovec_count = 1;
	c->recv_overlap.iovec = c->wrecvbuf;	
	refobj_init((refobj*)c,stream_conn_destroy);
	c->handle = sock;
	kn_sock_setud(sock,c);
	return c;
}

static void _force_close(stream_conn_t c,int err){
	if(c->on_disconnected) c->on_disconnected(c,err);
	if(c->sendtimer){ 				 
		kn_del_timer(c->sendtimer);
		c->sendtimer = NULL; 
	}
	refobj_dec((refobj*)c);	
}

int cb_lastsend(kn_timer_t t){
	printf("cb_lastsend\n");
	stream_conn_t c = (stream_conn_t)kn_timer_getud(t);
	_force_close(c,0);
	return 0;
}

void stream_conn_close(stream_conn_t c){
	if(c->is_close) return;
	c->is_close = 1;
	if(!c->doing_send){
		_force_close(c,0);
	}else{
		//添加定时器确保待发送数据发送完毕或发送超时才调用调用refobj_dec
		//c->send_timeout = 5*1000;
		engine_t e = kn_sock_engine(c->handle);
		if(e){
			if(c->sendtimer){
				 kn_del_timer(c->sendtimer);
				 c->sendtimer = NULL;
			}
			c->sendtimer = kn_reg_timer(e,5000,cb_lastsend,c);
			if(!c->sendtimer)
				_force_close(c,0);			
		}			
	} 	
}

void RecvFinish(stream_conn_t c,int32_t bytestransfer,int32_t err_code)
{
	uint32_t recv_size;
	uint32_t free_buffer_size;
	buffer_t buf;
	uint32_t pos;
	int32_t i = 0;
	if(bytestransfer == 0 || (bytestransfer < 0 && err_code != EAGAIN)){
		//不处理半关闭的情况，如果读到流的结尾直接关闭连接
		printf("recv close\n");
		_force_close(c,err_code);	
	}else if(bytestransfer > 0){
		update_next_recv_pos(c,bytestransfer);
		c->unpack_size += bytestransfer;
		int ret; 
		if((ret = unpack(c)) == -1){
			_force_close(c,err_code);	
			return;
		}
		if(ret != 0) return;
		//发出新的读请求
		buf = c->next_recv_buf;
		pos = c->next_recv_pos;
		recv_size = c->recv_bufsize;
		do
		{
			free_buffer_size = buf->capacity - pos;
			free_buffer_size = recv_size > free_buffer_size ? free_buffer_size:recv_size;
			c->wrecvbuf[i].iov_len = free_buffer_size;
			c->wrecvbuf[i].iov_base = buf->buf + pos;
			recv_size -= free_buffer_size;
			pos += free_buffer_size;
			if(recv_size && pos >= buf->capacity)
			{
				pos = 0;
				if(!buf->next)
					buf->next = buffer_create(c->recv_bufsize);
				buf = buf->next;
			}
			++i;
		}while(recv_size);
		c->recv_overlap.iovec_count = i;
		c->recv_overlap.iovec = c->wrecvbuf;
		kn_sock_recv(c->handle,&c->recv_overlap);
	}
}

void SendFinish(stream_conn_t c,int32_t bytestransfer,int32_t err_code)
{
	if(bytestransfer == 0 || (bytestransfer < 0 && err_code != EAGAIN)){
		_force_close(c,err_code);
	}else{
		update_send_list(c,bytestransfer);
		st_io *io = prepare_send(c);
		if(!io) {
			c->doing_send = 0;
			if(c->is_close){
				//数据发送完毕且收到关闭请求，可以安全关闭了
				_force_close(c,0);
			}
			return;
		}
		kn_sock_send(c->handle,io);		
	}
}

void IoFinish(handle_t sock,st_io *io,int32_t bytestransfer,int32_t err_code)
{
	stream_conn_t c = kn_sock_getud(sock);
	refobj_inc((refobj*)c);
	if(io == (st_io*)&c->send_overlap)
		SendFinish(c,bytestransfer,err_code);
	else if(io == (st_io*)&c->recv_overlap)
		RecvFinish(c,bytestransfer,err_code);
	else{
		_force_close(c,err_code);
	}
	refobj_dec((refobj*)c);
}

int stream_conn_send(stream_conn_t c,packet_t w)
{	
	if(packet_type(w) != WPACKET && packet_type(w) != RAWPACKET){
		destroy_packet(w);
		return -1;
	}	
	if(c->is_close){
		destroy_packet(w);
		return -1;
	}
	st_io *O;
	if(w){
		kn_list_pushback(&c->send_list,(kn_list_node*)w);
	}
	if(!c->doing_send){
		c->doing_send = 1;
		O = prepare_send(c);
		if(O) return kn_sock_send(c->handle,O);
	}
	return 0;
}

int stream_conn_associate(engine_t e,
			  stream_conn_t conn,
			  CCB_PROCESS_PKT on_packet,
			  CCB_DISCONNECTD on_disconnect)
{
		
      kn_sock_associate(conn->handle,e,IoFinish,NULL);
      if(on_packet) conn->on_packet = on_packet;
      if(on_disconnect) conn->on_disconnected = on_disconnect;
      if(e){
	  kn_sock_recv(conn->handle,&conn->recv_overlap);		
      }
      return 0;

}
