#include <stdlib.h>
#include "kn_thread.h"


kn_thread_t kn_create_thread(int32_t joinable)
{
	kn_thread_t t = calloc(1,sizeof(*t));
	t->joinable = joinable;
	return t;
}

void kn_thread_destroy(kn_thread_t t)
{
	free(t);
}

void* kn_thread_join(kn_thread_t t)
{
	void *result = 0;
	if(t->joinable)
		pthread_join(t->threadid,&result);
	return result;
}

void kn_thread_start_run(kn_thread_t t,kn_thread_routine r,void *arg)
{
	pthread_attr_t attr;
	if(!t)
		return;
	pthread_attr_init(&attr);
	if(t->joinable)
		pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_JOINABLE);
	else
		pthread_attr_setdetachstate(&attr,PTHREAD_CREATE_DETACHED);
	pthread_create(&t->threadid,&attr,r,arg);
	pthread_attr_destroy(&attr);
}

