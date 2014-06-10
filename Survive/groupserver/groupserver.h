#ifndef _GROURSERVER_H
#define _GROURSERVER_H

#include "log.h"

DEF_LOG(grouplog,"groupserver");

#define LOG_GATE(LOGLEV,...) LOG(GET_LOGFILE(grouplog),LOGLEV,__VA_ARGS__)


#endif