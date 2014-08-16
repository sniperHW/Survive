#ifndef _KENDYNET_PRIVATE_H
#define _KENDYNET_PRIVATE_H
#include "kendynet.h"

int      kn_event_add(engine_t,handle_t,int event);
int      kn_event_mod(engine_t,handle_t,int event);
int      kn_event_del(engine_t,handle_t);

static inline void     kn_set_noblock(int fd,int block){
    int flag = fcntl(fd, F_GETFL, 0);
    if (block) {
        flag &= (~O_NONBLOCK);
    } else {
        flag |= O_NONBLOCK;
    }
    fcntl(fd, F_SETFL, flag);
}


#endif
