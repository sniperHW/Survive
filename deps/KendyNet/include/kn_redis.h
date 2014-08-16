#ifndef _KN_REDIS_H
#define _KN_REDIS_H
#include "hiredis/hiredis.h"
typedef struct redisconn *redisconn_t;

int kn_redisAsynConnect(engine_t p,
						const char *ip,unsigned short port,
						void (*cb_connect)(redisconn_t,int err,void *ud),
						void (*cb_disconnected)(struct redisconn*,void *ud),
						void *ud
						);

struct redisReply;						
int kn_redisCommand(redisconn_t,const char *cmd,
					void (*cb)(redisconn_t,struct redisReply*,void *pridata),void *pridata);					

void kn_redisDisconnect(redisconn_t);



#endif
