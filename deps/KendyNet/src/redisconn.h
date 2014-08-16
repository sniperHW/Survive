#ifndef _REDISCONN_H
#define _REDISCONN_H

#include "kn_type.h"

//redis连接
#include "hiredis/hiredis.h"
#include "hiredis/async.h"
#include "kn_dlist.h"

typedef struct redisconn{
	handle                comm_head;
	engine_t              e;
	int                   events;
	int                   closing;
	redisAsyncContext*    context;
	void (*cb_connect)(struct redisconn*,int err,void *);
	void (*cb_disconnected)(struct redisconn*,void *);
	kn_dlist              pending_command;	
}redisconn,*redisconn_t;

#endif
