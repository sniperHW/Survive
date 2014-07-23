#ifndef _CONFIG_H
#define _CONFIG_H

#include "kn_string.h"

typedef struct config{
	//对gateserver连接的监听
	kn_string_t lgateip;
	uint16_t    lgateport;
}config;

extern config* g_config;

int loadconfig(); 








#endif
