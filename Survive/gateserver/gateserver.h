#ifndef _GATESERVER_H
#define _GATESERVER_H
#include "log.h"

DEF_LOG(gatelog,"gateserver");

#define LOG_GATE(LOGLEV,...) LOG(GET_LOGFILE(gatelog),LOGLEV,__VA_ARGS__)

#endif