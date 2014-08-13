#ifndef _CONFIG_H
#define _CONFIG_H

#include "kn_string.h"

typedef enum{
	GATESERVER = 1,
	GAMESERVER = 2,
}remoteServerType;

typedef struct config{
	kn_string_t listenip;
	uint16_t    listenport;
	//chatserver
	kn_string_t lchatip;
	uint16_t    lchatport;
	
}config;

extern config* g_config;

int loadconfig(); 








#endif
