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
#ifndef _KN_EXCEPT_H
#define _KN_EXCEPT_H
#include <setjmp.h>
#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <string.h>
#include <pthread.h>
#include <signal.h>
#include "kn_list.h"
#include "kn_exception.h"
#include "log.h"

typedef struct kn_callstack_frame
{
    kn_list_node node;
    char  info[1024];
}kn_callstack_frame;

typedef struct kn_exception_frame
{
    kn_list_node   node;
    sigjmp_buf jumpbuffer;
    int32_t exception;
    int32_t line; 
    const char   *file;
    const char   *func;
    void         *addr;
    int8_t  is_process;
    struct kn_list  call_stack; //函数调用栈记录 
	
}kn_exception_frame;

typedef struct kn_exception_perthd_st
{
	kn_list  expstack;
	kn_list  csf_pool;   //callstack_frame池
}kn_exception_perthd_st;

extern pthread_key_t g_exception_key;
extern pthread_once_t g_exception_key_once;


void kn_exception_once_routine();

static inline void kn_clear_callstack(kn_exception_frame *frame)
{
    kn_exception_perthd_st *epst = (kn_exception_perthd_st*)pthread_getspecific(g_exception_key);
	while(kn_list_size(&frame->call_stack) != 0)
		kn_list_pushback(&epst->csf_pool,kn_list_pop(&frame->call_stack));
}


static inline void print_call_stack(struct kn_exception_frame *frame)
{

    if(!frame)return;
    char buf[MAX_LOG_SIZE];
    char *ptr = buf;
    int32_t size = 0;
    kn_list_node *node = kn_list_head(&frame->call_stack);
    int f = 0;
    if(frame->exception == except_segv_fault)
	    size += snprintf(ptr,MAX_LOG_SIZE,"%s[invaild access addr:%p]\n",kn_exception_description(frame->exception),frame->addr);
    else
	    size += snprintf(ptr,MAX_LOG_SIZE,"%s\n",kn_exception_description(frame->exception));
    ptr = buf+size;
    while(node != NULL && size < MAX_LOG_SIZE)
    {
        struct kn_callstack_frame *cf = (struct kn_callstack_frame*)node;
        size += snprintf(ptr,MAX_LOG_SIZE-size,"% 2d: %s",++f,cf->info);
        ptr = buf+size;
        node = node->next;
    }
    SYS_LOG(LOG_ERROR,"%s",buf);
}

#define PRINT_CALL_STACK print_call_stack(&frame)


static inline kn_list *kn_GetCurrentThdExceptionStack()
{
	kn_exception_perthd_st *epst;
	kn_callstack_frame *call_frame;
	int32_t i;
	
    pthread_once(&g_exception_key_once,kn_exception_once_routine);
	epst = (kn_exception_perthd_st *)pthread_getspecific(g_exception_key);
	if(!epst)
	{
		epst = calloc(1,sizeof(*epst));
		for(i = 0;i < 256; ++i){
			call_frame = calloc(1,sizeof(*call_frame));
			kn_list_pushfront(&epst->csf_pool,&call_frame->node);
		}
        pthread_setspecific(g_exception_key,epst);
	}
	return &epst->expstack;
}

static inline void kn_expstack_push(kn_exception_frame *frame)
{
    kn_list *expstack = kn_GetCurrentThdExceptionStack();
	kn_list_pushfront(expstack,&frame->node);
}

static inline kn_exception_frame* kn_expstack_pop()
{
    kn_list *expstack = kn_GetCurrentThdExceptionStack();
    struct kn_exception_frame *frame = (kn_exception_frame*)kn_list_pop(expstack);
    return frame;
}

static inline kn_exception_frame* kn_expstack_top()
{
    kn_list *expstack = kn_GetCurrentThdExceptionStack();
    return (struct kn_exception_frame*)kn_list_head(expstack);
}

extern void kn_exception_throw(int32_t code,const char *file,const char *func,int32_t line,siginfo_t* info);

#define TRY do{\
	kn_exception_frame  frame;\
    frame.node.next = NULL;\
    frame.file = __FILE__;\
    frame.func = __FUNCTION__;\
    frame.exception = 0;\
    frame.is_process = 1;\
    kn_list_init(&frame.call_stack);\
    kn_expstack_push(&frame);\
    int savesigs= SIGSEGV | SIGBUS | SIGFPE;\
	if(sigsetjmp(frame.jumpbuffer,savesigs) == 0)
	
#define THROW(EXP) kn_exception_throw(EXP,__FILE__,__FUNCTION__,__LINE__,NULL)

#define CATCH(EXP) else if(!frame.is_process && frame.exception == EXP?\
                        frame.is_process=1,frame.is_process:frame.is_process)

#define CATCH_ALL else if(!frame.is_process?\
                        frame.is_process=1,frame.is_process:frame.is_process)

#define ENDTRY if(!frame.is_process)\
                    kn_exception_throw(frame.exception,frame.file,frame.func,frame.line,NULL);\
               else {\
                    kn_exception_frame *frame = kn_expstack_pop();\
                    kn_clear_callstack(frame);\
                }\
			}while(0);					

//#define FINALLY
/*根据当前函数中try的处理情况丢弃数量正确的异常栈,再返回*/
/*#define RETURN  do{struct exception_frame *top;\
                    while((top = expstack_top())!=NULL){\
                        if(top->file == __FILE__ && top->func == __FUNCTION__)\
                        {\
                            struct exception_frame *frame = expstack_pop();\
                            clear_call_stack(frame);\
                        }else\
                        break;\
                    };\
                }while(0);return
*/

#define RETURN  do{kn_exception_frame *top;\
                    while((top = kn_expstack_top())!=NULL){\
                        if(strcmp(top->file,__FILE__) == 0 && strcmp(top->func,__FUNCTION__) == 0)\
                        {\
                            kn_exception_frame *frame = kn_expstack_pop();\
                            kn_clear_callstack(frame);\
                        }else\
                        break;\
                    };\
                }while(0);return			

#define EXPNO frame.exception


#endif
