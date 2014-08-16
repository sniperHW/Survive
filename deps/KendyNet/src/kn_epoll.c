#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <fcntl.h>              /* Obtain O_* constant definitions */
#include <unistd.h>
#include "kendynet_private.h"
#include "kn_timer.h"
#include "kn_timer_private.h"
#include "kn_timerfd.h"
#include <assert.h>

struct st_notify{
	handle comm_head;
	int fd_write;
};

typedef struct{
	int epfd;
	struct epoll_event* events;
	int    eventsize;
	int    maxevents;
	handle_t timerfd;	
	struct st_notify notify_stop;
}kn_epoll;

int kn_event_add(engine_t e,handle_t h,int events){
	assert((events & EPOLLET) == 0);
	int ret;
	struct epoll_event ev = {0};
	kn_epoll *ep = (kn_epoll*)e;
	ev.data.ptr = h;
	ev.events = events;
	TEMP_FAILURE_RETRY(ret = epoll_ctl(ep->epfd,EPOLL_CTL_ADD,h->fd,&ev));
	if(ret != 0) return errno;
	++ep->eventsize;
	if(ep->eventsize > ep->maxevents){
		free(ep->events);
		ep->maxevents <<= 2;
		ep->events = calloc(1,sizeof(*ep->events)*ep->maxevents);
	}
	return 0;
}

int kn_event_mod(engine_t e,handle_t h,int events){
	assert((events & EPOLLET) == 0);	
	int ret;
	struct epoll_event ev = {0};
	kn_epoll *ep = (kn_epoll*)e;
	ev.data.ptr = h;
	ev.events = events;
	TEMP_FAILURE_RETRY(ret = epoll_ctl(ep->epfd,EPOLL_CTL_MOD,h->fd,&ev));
	return ret;	
}

int kn_event_del(engine_t e,handle_t h){
	kn_epoll *ep = (kn_epoll*)e;
	struct epoll_event ev = {0};
	int ret;
	TEMP_FAILURE_RETRY(ret = epoll_ctl(ep->epfd,EPOLL_CTL_DEL,h->fd,&ev));
	if(0 == ret){ 
		--ep->eventsize;
	}
	return ret;	
}

engine_t kn_new_engine(){
	int epfd = epoll_create1(EPOLL_CLOEXEC);
	if(epfd < 0) return NULL;
	int tmp[2];
	if(pipe2(tmp,O_NONBLOCK|O_CLOEXEC) != 0){
		close(epfd);
		return NULL;
	}		
	kn_epoll *ep = calloc(1,sizeof(*ep));
	ep->epfd = epfd;
	ep->maxevents = 1024;
	ep->events = calloc(1,(sizeof(*ep->events)*ep->maxevents));
	ep->notify_stop.comm_head.fd = tmp[0];
	ep->notify_stop.fd_write = tmp[1];
	//kn_set_noblock(tmp[0],0); 
	//kn_set_noblock(tmp[1],0); 
	kn_event_add(ep,(handle_t)&ep->notify_stop,EPOLLIN);
	
	ep->timerfd = kn_new_timerfd(1);
	((handle_t)ep->timerfd)->ud = kn_new_timermgr();
	kn_event_add(ep,ep->timerfd,EPOLLIN | EPOLLOUT);	
	return (engine_t)ep;
}

void kn_release_engine(engine_t e){
	kn_epoll *ep = (kn_epoll*)e;
	close(ep->epfd);
	close(ep->notify_stop.comm_head.fd);
	close(ep->notify_stop.fd_write);
	free(ep->events);
	free(ep);
}

int kn_engine_run(engine_t e){
	kn_epoll *ep = (kn_epoll*)e;
	for(;;){
		errno = 0;
		int i;
		handle_t h;
		int nfds = TEMP_FAILURE_RETRY(epoll_wait(ep->epfd,ep->events,ep->maxevents,1000));
		if(nfds > 0){
			for(i=0; i < nfds ; ++i)
			{
				h = (handle_t)ep->events[i].data.ptr;
				if(h){ 
					if(h == (handle_t)&ep->notify_stop){
						for(;;){
							char buf[4096];
							int ret = TEMP_FAILURE_RETRY(read(h->fd,buf,4096));
							if(ret <= 0) break;
						}
						return 0;
					}else
						h->on_events(h,ep->events[i].events);
				}
			}
		}
	}
}

void kn_stop_engine(engine_t e){
	kn_epoll *ep = (kn_epoll*)e;
	char buf[1];
	TEMP_FAILURE_RETRY(write(ep->notify_stop.fd_write,buf,1));
}


kn_timer_t kn_reg_timer(engine_t e,uint64_t timeout,kn_cb_timer cb,void *ud){
	kn_epoll *ep = (kn_epoll*)e;
	return reg_timer_imp(((handle_t)ep->timerfd)->ud,timeout,cb,ud);
}
