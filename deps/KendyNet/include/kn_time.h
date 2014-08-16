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
#ifndef _KN_SYSTIME_H
#define _KN_SYSTIME_H
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include "kn_common_include.h"
#include <pthread.h>

extern pthread_key_t g_systime_key;
extern pthread_once_t g_systime_key_once;

struct _clock
{
    uint64_t last_tsc;
    uint64_t last_time;
};

#define NN_CLOCK_PRECISION 1000000

static inline uint64_t _clock_rdtsc ()
{
#if (defined _MSC_VER && (defined _M_IX86 || defined _M_X64))
    return __rdtsc ();
#elif (defined __GNUC__ && (defined __i386__ || defined __x86_64__))
    uint32_t low;
    uint32_t high;
    __asm__ volatile ("rdtsc" : "=a" (low), "=d" (high));
    return (uint64_t) high << 32 | low;
#elif (defined __SUNPRO_CC && (__SUNPRO_CC >= 0x5100) && (defined __i386 || \
    defined __amd64 || defined __x86_64))
    union {
        uint64_t u64val;
        uint32_t u32val [2];
    } tsc;
    asm("rdtsc" : "=a" (tsc.u32val [0]), "=d" (tsc.u32val [1]));
    return tsc.u64val;
#else
    /*  RDTSC is not available. */
    return 0;
#endif
}

static inline uint64_t _clock_time ()
{
    struct timespec tv;
    clock_gettime (CLOCK_REALTIME, &tv);
    return tv.tv_sec * (uint64_t) 1000 + tv.tv_nsec / 1000000;
}

static inline void _clock_init (struct _clock *c)
{
    c->last_tsc = _clock_rdtsc ();
    c->last_time = _clock_time ();
}

static inline struct _clock* get_thread_clock()
{
	struct _clock* c = (struct _clock*)pthread_getspecific(g_systime_key);
	if(!c){
	   c = calloc(1,sizeof(*c));
       _clock_init(c);
       pthread_setspecific(g_systime_key,c);
	}
	return c;
}


static void systick_once_routine(){
    pthread_key_create(&g_systime_key,NULL);
}

static inline uint64_t kn_systemms64()
{
	pthread_once(&g_systime_key_once,systick_once_routine);
    uint64_t tsc = _clock_rdtsc ();
    if (!tsc)
        return _clock_time ();

    struct _clock *c = get_thread_clock();

    /*  If tsc haven't jumped back or run away too far, we can use the cached
        time value. */
    if (tsc - c->last_tsc <= (NN_CLOCK_PRECISION / 2) && tsc >= c->last_tsc)
        return c->last_time;

    /*  It's a long time since we've last measured the time. We'll do a new
        measurement now. */
    c->last_tsc = tsc;
    c->last_time = _clock_time ();
    return c->last_time;
}

static inline uint32_t kn_systemms()
{
    return (uint32_t)kn_systemms64();
}

static inline time_t kn_systemsec()
{
	return time(NULL);
}

static inline void kn_sleepms(uint32_t ms)
{
	uint64_t endtick = kn_systemms64()+ms;
	do{
		uint64_t _ms = endtick - kn_systemms64();
		usleep(_ms*1000);
	}while(kn_systemms64() < endtick);
}

/*
static inline char *GetCurrentTimeStr(char *buf)
{
	time_t _now = time(NULL);
#ifdef _WIN
	struct tm *_tm;
	_tm = localtime(&_now);
	snprintf(buf,22,"[%04d-%02d-%02d %02d:%02d:%02d]",_tm->tm_year+1900,_tm->tm_mon+1,_tm->tm_mday,_tm->tm_hour,_tm->tm_min,_tm->tm_sec);
#else
	struct tm _tm;
	localtime_r(&_now, &_tm);
	snprintf(buf,22,"[%04d-%02d-%02d %02d:%02d:%02d]",_tm.tm_year+1900,_tm.tm_mon+1,_tm.tm_mday,_tm.tm_hour,_tm.tm_min,_tm.tm_sec);
#endif
	return buf;
}*/
#endif
