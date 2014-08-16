#include "kn_timer.h"
#include "kn_timer_private.h"
#include "kn_timerfd.h"
#include <sys/timerfd.h> 

void kn_timerfd_on_active(handle_t s,int event){
	kn_timerfd_t t = (kn_timerfd_t)s;
	long long tmp;
	errno = 0;
	TEMP_FAILURE_RETRY(read(t->comm_head.fd,&tmp,sizeof(tmp)));
	if(errno == 0){
		kn_timermgr_t mgr = (kn_timermgr_t)t->comm_head.ud;
		kn_timermgr_tick(mgr);
	}
}

void kn_timerfd_destroy(void *ptr){
	kn_timerfd_t t = (kn_timerfd_t)ptr;
	close(t->comm_head.fd);
	free(t);
}

handle_t kn_new_timerfd(uint32_t timeout){
	kn_timerfd_t fd = calloc(1,sizeof(*fd));
	fd->comm_head.fd = timerfd_create(CLOCK_MONOTONIC,TFD_CLOEXEC|TFD_NONBLOCK);
	if(fd->comm_head.fd < 0){
		free(fd);
		return NULL;
	}
	struct itimerspec spec;
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    int sec = timeout/1000;
    int ms = timeout%1000;    
    long long nosec = (now.tv_sec + sec)*1000*1000*1000 + now.tv_nsec + ms*1000*1000;
	spec.it_value.tv_sec = nosec/(1000*1000*1000);
    spec.it_value.tv_nsec = nosec%(1000*1000*1000);
    spec.it_interval.tv_sec = sec;
    spec.it_interval.tv_nsec = ms*1000*1000;	
	
	if(0 != timerfd_settime(fd->comm_head.fd,TFD_TIMER_ABSTIME,&spec,0))
	{
		close(fd->comm_head.fd);
		free(fd);
		return NULL;
	}
	fd->comm_head.on_events = kn_timerfd_on_active;
	return (handle_t)fd;
}
