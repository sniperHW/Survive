/*
    Copyright (C) <2014>  <huangweilook@21cn.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef _KN_THREAD_SYNC_H
#define _KN_THREAD_SYNC_H
#include <pthread.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/time.h>
#include <errno.h>
/*Mutex*/
typedef struct kn_mutex
{
	pthread_mutex_t     m_mutex;
	pthread_mutexattr_t m_attr;
}*kn_mutex_t;


static inline int32_t kn_mutex_lock(kn_mutex_t m)
{
	return pthread_mutex_lock(&m->m_mutex);
}

static inline int32_t kn_mutex_trylock(kn_mutex_t m)
{
	return pthread_mutex_trylock(&m->m_mutex);
}

static inline int32_t kn_mutex_unlock(kn_mutex_t m)
{
	return pthread_mutex_unlock(&m->m_mutex);
}

static inline kn_mutex_t kn_mutex_create()
{
	kn_mutex_t m = malloc(sizeof(*m));
	pthread_mutexattr_init(&m->m_attr);
	pthread_mutexattr_settype(&m->m_attr,PTHREAD_MUTEX_RECURSIVE_NP);
	pthread_mutex_init(&m->m_mutex,&m->m_attr);
	return m;
}

static inline void kn_mutex_destroy(kn_mutex_t m)
{
	pthread_mutexattr_destroy(&m->m_attr);
	pthread_mutex_destroy(&m->m_mutex);
	free(m);
}

/*Condition*/
typedef struct kn_condition
{
	pthread_cond_t cond;
}*kn_condition_t;


static inline int32_t kn_condition_wait(kn_condition_t c,kn_mutex_t m)
{
	return pthread_cond_wait(&c->cond,&m->m_mutex);
}


static inline int32_t imp_condition_timedwait(kn_condition_t c,kn_mutex_t m,int32_t ms)
{
	struct timespec ts;
	uint64_t msec;
	
	clock_gettime(CLOCK_REALTIME, &ts);
	msec = ms%1000;
	ts.tv_nsec += (msec*1000*1000);
	ts.tv_sec  += (ms/1000);
	if(ts.tv_nsec >= 1000*1000*1000){
		ts.tv_sec += 1;
		ts.tv_nsec %= (1000*1000*1000);
	}
	return pthread_cond_timedwait(&c->cond,&m->m_mutex,&ts);
}

static inline int32_t kn_condition_timedwait(kn_condition_t c,kn_mutex_t m,int32_t ms)
{
	struct timespec ts;
	uint32_t cur_tick;
	uint32_t timeout;
	int32_t ret;
	
	clock_gettime(CLOCK_REALTIME, &ts);
	cur_tick =ts.tv_sec * 1000 + ts.tv_nsec/1000000;
	timeout = cur_tick + (uint32_t)ms;
	for(;;){
		ret = imp_condition_timedwait(c,m,ms);
		if(ret == 0 || errno != EINTR)
			return ret;
		clock_gettime(CLOCK_REALTIME, &ts);
		cur_tick =ts.tv_sec * 1000 + ts.tv_nsec/1000000; 
		if(timeout > cur_tick)
			ms = timeout - cur_tick;
		else{
			errno = ETIMEDOUT;
			return ret;
		}
	}
	return 0;
}

static inline int32_t kn_condition_signal(kn_condition_t c)
{
	return pthread_cond_signal(&c->cond);
}

static inline int32_t kn_condition_broadcast(kn_condition_t c)
{
	return pthread_cond_broadcast(&c->cond);
}

static inline kn_condition_t kn_condition_create()
{
	kn_condition_t c = malloc(sizeof(*c));
	pthread_cond_init(&c->cond,NULL);
	return c;
}

static inline void kn_condition_destroy(kn_condition_t c)
{
	pthread_cond_destroy(&c->cond);
	free(c);
}

/*
typedef struct barrior
{
	condition_t cond;
	mutex_t 	mtx;
	int32_t     wait_count;
}*barrior_t;

static inline void barrior_wait(barrior_t b)
{
	mutex_lock(b->mtx);
	--b->wait_count;
	if(0 == b->wait_count)
	{
		condition_broadcast(b->cond);
	}else
	{
		while(b->wait_count > 0)
		{
			condition_wait(b->cond,b->mtx);
		}
	}
	mutex_unlock(b->mtx);
}

static inline barrior_t barrior_create(int waitcount)
{
	barrior_t b = malloc(sizeof(*b));
	b->wait_count = waitcount;
	b->mtx = mutex_create();
	b->cond = condition_create();
	return b;
}

static inline void barrior_destroy(barrior_t *b)
{
	mutex_destroy(&(*b)->mtx);
	condition_destroy(&(*b)->cond);
	free(*b);
	*b = 0;
}
*/
#endif
