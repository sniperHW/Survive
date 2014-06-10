#ifndef _CONFIG_H
#define _CONFIG_H

#include "kn_string.h"

enum{
	GROUPSERVER = 1,
	GAMESERVER = 2,
}remoteServerType,

typedef struct config{
	kn_string_t groupip;
	uint16_t    groupport;
	uint8_t     agentcount;
	kn_string_t toclientip;
	uint16_t    toclientport;
}config;

extern config* g_config;

int loadconfig(); 








#endif