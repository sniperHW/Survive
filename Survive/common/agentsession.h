#ifndef _AGENTSESSION_H
#define _AGENTSESSION_H
#include <stdint.h>
#include "wpacket.h"
#include "rpacket.h"

#define MAX_AGENT_PLAYER 4096
typedef struct agentsession{
	union{
		struct{
			uint64_t aid:3;            //agentservice的编号0-7
			uint64_t sessionid:13;     //用户在agentservice中的下标,1-4095
			uint64_t identity:48;      
		};
		struct{
			uint32_t high;
			uint32_t low;
		};
		uint64_t     data;
	};
}agentsession;

static inline void wpk_write_agentsession(wpacket_t wpk,agentsession *session){
	wpk_write_uint32(wpk,session->high);
	wpk_write_uint32(wpk,session->low);
}

static inline void rpk_read_agentsession(rpacket_t rpk,agentsession *session){
	session->high = rpk_read_uint32(rpk);
	session->low = rpk_read_uint32(rpk);
}

#endif
