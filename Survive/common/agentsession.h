#ifndef _AGENTSESSION_H
#define _AGENTSESSION_H
#include <stdint.h>
#define MAX_AGENT_PLAYER 4096
typedef struct agentsession{
	union{
		struct{
			uint64_t aid:3;            //agentservice的编号0-7
			uint64_t sessionid:13;     //用户在agentservice中的下标,1-4095
			uint64_t identity:48;      
		};
		uint64_t     data;
	};
}agentsession;

#endif
