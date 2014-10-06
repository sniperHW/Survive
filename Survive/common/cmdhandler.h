#ifndef _CMDHANDLER_H
#define _CMDHANDLER_H

#include <stdint.h>

struct rpacket;
typedef struct cmd_handler{
	void (*_fn)(struct rpacket*,void *);//for C function	
}*cmd_handler_t;


#define REG_C_HANDLER(CMD,HANDLER) do{\
				cmd_handler_t h = calloc(1,sizeof(*h));\
				h->_fn = HANDLER;\
				handler[CMD] = h;\
				}while(0)


#endif
