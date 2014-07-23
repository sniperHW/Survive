#ifndef _GAMESERVER_H
#define _GAMESERVER_H

#include "log.h"

DEF_LOG(gamelog,"gameserver");

#define LOG_GAME(LOGLEV,...) LOG(GET_LOGFILE(gamelog),LOGLEV,__VA_ARGS__)


#endif
