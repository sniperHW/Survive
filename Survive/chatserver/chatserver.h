#ifndef _GROURSERVER_H
#define _GROURSERVER_H

#include "log.h"

DEF_LOG(chatlog,"chatserver");

#define LOG_CHAT(LOGLEV,...) LOG(GET_LOGFILE(grouplog),LOGLEV,__VA_ARGS__)


#endif
