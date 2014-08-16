#ifndef _KN_TIMER_PRIVATE_H
#define _KN_TIMER_PRIVATE_H

typedef struct kn_timermgr *kn_timermgr_t;

kn_timermgr_t kn_new_timermgr();

kn_timer_t reg_timer_imp(kn_timermgr_t t,uint64_t timeout,kn_cb_timer cb,void *ud);

void kn_timermgr_tick(kn_timermgr_t t);

#endif
