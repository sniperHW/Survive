#ifndef _CMDHANDLER_H
#define _CMDHANDLER_H

#include <stdint.h>
#include "lua_util.h"

struct rpacket;
enum{
	FN_C=1,
	FN_LUA,
};

typedef struct cmd_handler{
	uint8_t _type;
	union{
		void (*_fn)(struct rpacket*,void *);//for C function
		luaTabRef_t *obj;                    //for lua function
	};
}*cmd_handler_t;


#define REG_C_HANDLER(CMD,HANDLER) do{\
				cmd_handler_t h = calloc(1,sizeof(*h));\
				h->_type = FN_C;\
				h->_fn = HANDLER;\
				handler[CMD] = h;\
				}while(0)


#endif
