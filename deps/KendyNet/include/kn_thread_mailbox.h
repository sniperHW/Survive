#ifndef _KN_THREAD_MAILBOX_H
#define _KN_THREAD_MAILBOX_H

#include "kn_refobj.h"
#include "kendynet.h"

/*
 * 快速模式和公平模式
 * 快速模式:消息处理优先级最高,会尽量多的从队列中提取消息并执行消息回调.
 * 公平模式:不管队列中有多少消息,每次仅提取一个消息并执行消息回调. 
 */ 

enum{
	MODE_FAST = 1,
	MODE_FAIR = 2,
};

//线程邮箱,每个线程有一个唯一的线程邮箱用于接收其它线程发过来的消息
typedef ident kn_thread_mailbox_t;

typedef void (*cb_on_mail)(kn_thread_mailbox_t *from,void *);

void kn_setup_mailbox(engine_t,int mode,cb_on_mail);

int  kn_send_mail(kn_thread_mailbox_t,void*,void (*fn_destroy)(void*));

//获得当前线程的mailbox
kn_thread_mailbox_t kn_self_mailbox();

//根据线程id查询mailbox
kn_thread_mailbox_t kn_query_mailbox(pthread_t);

#endif
