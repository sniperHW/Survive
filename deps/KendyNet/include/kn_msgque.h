#ifndef _KN_MSGQUE_H
#define _KN_MSGQUE_H

#include "kn_refobj.h"
/*
*  普通单向消息队列
*  一个线程在一个消息队列上只能处于一种模式，要么是reader要么是writer 
*  与thread_mailbox的区别:
*  1) 支持多读多写
*  2) 不使用管道作为通知机制,所以不能和engine一起工作
*  3) 适合主消息队列，消费者线程池的工作模式 
*/

enum{
	MSGQUE_CLOSE = -1,
	INVAILD_MSG  = -2,
	OPEN_ERROR   = -3,
	INVAILD_MSGQUE = -4,
}; 

typedef ident  kn_msgque_t;
typedef struct kn_msgque_reader* kn_msgque_reader_t;
typedef struct kn_msgque_writer* kn_msgque_writer_t;

kn_msgque_t kn_new_msgque(int buffsize);
void        kn_close_msgque(kn_msgque_t);

kn_msgque_reader_t kn_open_reader(kn_msgque_t);
void kn_close_reader(kn_msgque_reader_t);

//ms == 0不等待,ms < 0 无限等待
int  kn_msgque_read(kn_msgque_reader_t, void **,int ms);

kn_msgque_writer_t kn_open_writer(kn_msgque_t);
void kn_close_writer(kn_msgque_writer_t);
int  kn_msgque_write(kn_msgque_writer_t,void*,void (*fn_destroy)(void*));
int  kn_msgque_flush(kn_msgque_writer_t);


#endif
