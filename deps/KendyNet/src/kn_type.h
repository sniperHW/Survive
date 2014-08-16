#ifndef _KN_TYPE
#define _KN_TYPE
#include "kendynet_private.h"

typedef struct handle{
	int type;
	int status;
	int fd;
	void *ud;
	void (*on_events)(handle_t,int events);
}handle;


enum{
	KN_SOCKET = 1,
	KN_TIMERFD,
	KN_CHRDEV,
	KN_REDISCONN,
	KN_MAILBOX,
};

#endif
