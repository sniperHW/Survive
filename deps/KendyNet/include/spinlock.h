/*
    Copyright (C) <2012>  <huangweilook@21cn.com>

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
#ifndef _SPINLOCK_H
#define _SPINLOCK_H
#include "kn_atomic.h"
#include <pthread.h>
#include <time.h>
#include <stdlib.h>
#include <assert.h>

typedef struct spinlock
{
	volatile   pthread_t  owner;
	int32_t    lock_count;
}*spinlock_t;

spinlock_t spin_create();
void       spin_destroy(spinlock_t);

static inline int32_t spin_lock(spinlock_t l)
{
#ifdef _WIN
	pthread_t tid = pthread_self();
	if(tid.p == l->owner.p)
	{
		++l->lock_count;
		return 0;
	}
	int32_t c,max;
	while(1)
	{
		if(l->owner.p == 0)
		{
			if(COMPARE_AND_SWAP(&(l->owner.p),0,tid.p))
				break;
		}
		for(c = 0; c < (max = rand()%4096); ++c)
			__asm__("pause");
	};
	++l->lock_count;
	return 0;
#else
	pthread_t tid = pthread_self();
	if(tid == l->owner)
	{
		++l->lock_count;
		return 0;
	}
	int32_t c,max;
	while(1)
	{
		if(l->owner == 0)
		{
			if(COMPARE_AND_SWAP(&(l->owner),0,tid))
				break;
		}
		for(c = 0; c < (max = rand()%4096); ++c)
			__asm__("pause");
	};
	++l->lock_count;
	return 0;
#endif
}

static inline int32_t spin_unlock(spinlock_t l)
{
#ifdef _WIN
	pthread_t tid = pthread_self();
	if(tid.p == l->owner.p && --l->lock_count == 0){
		l->owner.p = 0;
		return 0;
	}
	return -1;
#else
	pthread_t tid = pthread_self();
	if(tid == l->owner && --l->lock_count == 0){
		l->owner = 0;
		return 0;
	}
	return -1;
#endif
}

#endif
