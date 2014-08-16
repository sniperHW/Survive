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
#ifndef _KN_REFOBJ_H
#define _KN_REFOBJ_H

#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>
#include <signal.h>
#include <assert.h>
#include "kn_atomic.h"
#include "kn_except.h"  
  
typedef  void (*refobj_destructor)(void*);

typedef struct refobj
{
        atomic_32_t refcount;
        union{
            struct{
                uint32_t low32; 
                uint32_t high32;       
            };
            atomic_64_t identity;
        };
        atomic_32_t flag;
        void (*destructor)(void*);
}refobj;

void refobj_init(refobj *r,void (*destructor)(void*));

static inline atomic_32_t refobj_inc(refobj *r)
{
    return ATOMIC_INCREASE(&r->refcount);
}

static inline atomic_32_t refobj_dec(refobj *r)
{
    atomic_32_t count;
    int c;
    struct timespec ts;
    assert(r->refcount > 0);
    if((count = ATOMIC_DECREASE(&r->refcount)) == 0){
        r->identity = 0;
        c = 0;
        for(;;){
            if(COMPARE_AND_SWAP(&r->flag,0,1))
                break;
            if(c < 4000){
                ++c;
                __asm__("pause");
            }else{
                ts.tv_sec = 0;
                ts.tv_nsec = 500000;
                nanosleep(&ts, NULL);
            }
        }
        r->destructor(r);
    }
    return count;
}


typedef struct ident{
	union{	
		struct{ 
			uint64_t identity;    
			refobj   *ptr;
		};
		uint32_t _data[4];
	};
}ident;

static inline ident make_ident(refobj *ptr)
{
	ident _ident = {.identity=ptr->identity,.ptr=ptr};
    return _ident;
}

static inline refobj *cast2refobj(ident _ident)
{
    refobj *ptr = NULL;
    if(!_ident.ptr) return NULL;
    TRY{
		refobj *o = _ident.ptr;    
        while(_ident.identity == o->identity)
        {
            if(COMPARE_AND_SWAP(&o->flag,0,1))
            {                
                if(_ident.identity == o->identity &&refobj_inc(o) > 0)
                        ptr = o;
                o->flag = 0;
                break;
            }
        }
    }CATCH_ALL
    {
        ptr = NULL;      
    }ENDTRY;
    return ptr; 
}

static inline void make_empty_ident(ident *_ident)
{
    _ident->identity = 0;
    _ident->ptr = NULL;
}

static inline int is_empty_ident(ident ident){
	return ident.ptr == NULL ? 1 : 0;
}

#endif
