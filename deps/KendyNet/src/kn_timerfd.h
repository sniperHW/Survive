#ifndef _KN_TIMERFD_H
#define _KN_TIMERFD_H

#include "kn_type.h"
#include "kn_timer_private.h"

typedef struct kn_timerfd{
	handle comm_head;
}kn_timerfd,*kn_timerfd_t;

handle_t kn_new_timerfd(uint32_t timeout);
void     kn_timermgr_tick(kn_timermgr_t t);

#endif
