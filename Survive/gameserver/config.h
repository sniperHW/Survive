#ifndef _CONFIG_H
#define _CONFIG_H

#include "kn_string.h"

typedef enum{
	GATESERVER = 1,
	GROUPSERVER = 2,
}remoteServerType;

typedef struct config{
	//对gateserver连接的监听
	kn_string_t lgateip;
	uint16_t    lgateport;
	//groupserver服务器
	kn_string_t groupip;
	uint16_t    groupport;
	//chatserver
	kn_string_t chatip;
	uint16_t    chatport;	
}config;

extern config* g_config;

int loadconfig(); 








#endif
