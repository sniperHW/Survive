#ifndef _CMDHANDLER_H
#define _CMDHANDLER_H

#include <stdint.h>
#include "kn_string.h"
#include "lua/lua_util.h"

struct rpacket;
enum{
	FN_C=1,
	FN_LUA,
};

typedef struct cmd_handler{
	uint8_t _type;
	union{
		void (*_fn)(struct rpacket*,void *);//for C function
		luaObject_t obj;                    //for lua function
	};
}*cmd_handler_t;


#endif