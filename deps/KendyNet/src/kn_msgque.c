#include "kn_msgque.h"
#include "kn_thread_sync.h"
#include "kn_list.h"
#include "kn_dlist.h"
#include "kn_time.h"

typedef struct kn_msgque{
	refobj             ref;
	pthread_key_t      tkey;
	kn_mutex_t         mtx;
	kn_list            shareque;
	kn_dlist           waits;
	int                buffsize;
	volatile int       closing;
}kn_msgque;

typedef struct kn_msgque_writer{
	kn_msgque*  msgque;
	kn_list     writebuff;
	int         buffsize;
}*kn_msgque_writer_t;


typedef struct kn_msgque_reader{
	kn_dlist_node  waitnode;
	kn_msgque*     msgque;
	kn_list        readbuff;
	kn_condition_t cond;	
}*kn_msgque_reader_t;

struct msg{
	kn_list_node      node;
	void (*fn_destroy)(void*);
	void *data;	
};

static void msgque_destructor(void *ptr){
	kn_msgque* msgque = (kn_msgque*)ptr;
	struct msg *m;
	while((m = (struct msg*)kn_list_pop(&msgque->shareque)) != NULL){
		if(m->fn_destroy) m->fn_destroy(m->data);
		free(m);
	}
	kn_mutex_destroy(msgque->mtx);
	free(ptr);
}


kn_msgque_t kn_new_msgque(int buffsize){
	kn_msgque* msgque = calloc(1,sizeof(*msgque));
	if(buffsize < 0) buffsize = 0;
	msgque->buffsize = buffsize;
	msgque->mtx = kn_mutex_create();
	pthread_key_create(&msgque->tkey,NULL);
	kn_list_init(&msgque->shareque);
	kn_dlist_init(&msgque->waits);
	refobj_init((refobj*)msgque,msgque_destructor);
	return make_ident((refobj*)msgque);
}


void kn_close_msgque(kn_msgque_t _msgque){
	kn_msgque *msgque = (kn_msgque*)cast2refobj(_msgque);
	if(msgque){
		kn_mutex_lock(msgque->mtx);
		do{
			if(msgque->closing) break;
			msgque->closing = 1;
			//唤醒waits
			kn_msgque_reader_t reader;
			while((reader = (kn_msgque_reader_t)kn_dlist_pop(&msgque->waits)))
				kn_condition_signal(reader->cond);								
		}while(0);
		kn_mutex_lock(msgque->mtx);
		refobj_dec((refobj*)msgque);
	}
}


kn_msgque_reader_t kn_open_reader(kn_msgque_t _msgque){
	kn_msgque *msgque = (kn_msgque*)cast2refobj(_msgque);
	errno = 0;
	if(!msgque){
		errno = INVAILD_MSGQUE; 
		return NULL;
	}	
	if(pthread_getspecific(msgque->tkey)){
		refobj_dec((refobj*)msgque);
		errno = OPEN_ERROR;
		return NULL;
	}
	kn_mutex_lock(msgque->mtx);
	if(msgque->closing){
		kn_mutex_unlock(msgque->mtx);
		refobj_dec((refobj*)msgque);
		errno = MSGQUE_CLOSE;
		return NULL;
	}
	kn_mutex_unlock(msgque->mtx);
	//后面不需要调用refobj_dec,因为reader持有msgque的引用
	kn_msgque_reader_t reader = calloc(1,sizeof(*reader));
	reader->msgque = msgque;
	reader->cond   = kn_condition_create();
	kn_list_init(&reader->readbuff);
	pthread_setspecific(msgque->tkey,reader);
	return reader;	
}


kn_msgque_writer_t kn_open_writer(kn_msgque_t _msgque){
	kn_msgque *msgque = (kn_msgque*)cast2refobj(_msgque);
	errno = 0;
	if(!msgque){
		errno = INVAILD_MSGQUE; 
		return NULL;
	}	
	if(pthread_getspecific(msgque->tkey)){
		refobj_dec((refobj*)msgque);
		errno = OPEN_ERROR;
		return NULL;
	}
	kn_mutex_lock(msgque->mtx);
	if(msgque->closing){
		kn_mutex_unlock(msgque->mtx);
		refobj_dec((refobj*)msgque);
		errno = MSGQUE_CLOSE;
		return NULL;
	}
	kn_mutex_unlock(msgque->mtx);
	//后面不需要调用refobj_dec,因为reader持有msgque的引用	
	kn_msgque_writer_t writer = calloc(1,sizeof(*writer));
	writer->buffsize = msgque->buffsize;
	writer->msgque = msgque;
	kn_list_init(&writer->writebuff);
	pthread_setspecific(msgque->tkey,writer);
	return writer;			
}


static inline int write_nobuff(kn_msgque*  msgque,struct msg *msg){
	errno = 0;
	kn_mutex_lock(msgque->mtx);
	kn_list_pushback(&msgque->shareque,(kn_list_node*)msg);	
	if(msgque->closing){
		kn_mutex_lock(msgque->mtx);
		errno = MSGQUE_CLOSE;
		return -1;
	}
	//检查是否有wait的线程
	kn_msgque_reader_t reader = (kn_msgque_reader_t)kn_dlist_pop(&msgque->waits);
	if(reader) kn_condition_signal(reader->cond);
	kn_mutex_unlock(msgque->mtx);
	return 0;
}


static inline int msgque_flush(kn_msgque_writer_t writer){
	errno = 0;
	kn_msgque*  msgque = writer->msgque;
	kn_mutex_lock(msgque->mtx);
	if(msgque->closing){
		kn_mutex_lock(msgque->mtx);
		errno = MSGQUE_CLOSE;
		return -1;
	}	
	kn_list_swap(&msgque->shareque,&writer->writebuff);
	//检查是否有wait的线程
	kn_msgque_reader_t reader = (kn_msgque_reader_t)kn_dlist_pop(&msgque->waits);
	if(reader) kn_condition_signal(reader->cond);		
	kn_mutex_unlock(msgque->mtx);
	return 0;
}

static inline int write_buff(kn_msgque_writer_t writer,struct msg *msg){
	//先写入本线程缓存
	int ret = 0;
	kn_list_pushback(&writer->writebuff,(kn_list_node*)msg);
	if(kn_list_size(&writer->writebuff) >= writer->buffsize){
		ret = msgque_flush(writer);
	}
	return ret;
}

int  kn_msgque_write(kn_msgque_writer_t writer,void *_msg,void (*fn_destroy)(void*))
{
	errno = 0;
	if(!_msg){
		 errno = INVAILD_MSG;
		 return -1;
	 }
	struct msg *msg = calloc(1,sizeof(*msg));
	msg->fn_destroy = fn_destroy;
	msg->data = _msg;
	int ret;
	if(writer->buffsize)
		ret = write_buff(writer,msg);
	else
		ret = write_nobuff(writer->msgque,msg);	
	return ret;
}

int  kn_msgque_flush(kn_msgque_writer_t writer){
	return msgque_flush(writer);
}


static inline int _wait(kn_msgque_reader_t reader,int ms){
	kn_msgque*  msgque = reader->msgque;	
	if(ms > 0){
		uint32_t timeout = kn_systemms() + (uint32_t)ms;
		kn_dlist_push(&msgque->waits,(kn_dlist_node*)reader);
		while(kn_list_size(&msgque->shareque) == 0 && !msgque->closing){
			uint32_t now = kn_systemms();
			uint32_t sleepms = timeout > now ? timeout - now : 0;
			if(!sleepms) 
				break;
			if(0 != kn_condition_timedwait(reader->cond,msgque->mtx,(int32_t)sleepms)){
				break;
			}
		}
		kn_dlist_remove((kn_dlist_node*)reader);
	}else if(ms < 0){
		//无限等待
		kn_dlist_push(&msgque->waits,(kn_dlist_node*)reader);
		while(kn_list_size(&msgque->shareque) == 0 && !msgque->closing){
			if(0 != kn_condition_wait(reader->cond,msgque->mtx))
				break;
		}
		kn_dlist_remove((kn_dlist_node*)reader);
		kn_list_swap(&reader->readbuff,&msgque->shareque);
	}else{
		//不等待
		kn_list_swap(&reader->readbuff,&msgque->shareque);
	}
	return kn_list_size(&reader->readbuff);	
}

int  kn_msgque_read(kn_msgque_reader_t reader, void **msg,int ms){
	errno = 0;
	struct msg *m = NULL;
	*msg = NULL;
	int ret = 0;	
	kn_msgque*  msgque = reader->msgque;	
	m = (struct msg*)kn_list_pop(&reader->readbuff);
	if(m){
		*msg = m->data;
		free(m);
		return ret;
	}
	kn_mutex_lock(msgque->mtx);	
	do{
		if(msgque->closing){
			ret = -1;
			errno = MSGQUE_CLOSE;
			break;
		}
		if(_wait(reader,ms)){
			m = (struct msg*)kn_list_pop(&reader->readbuff);
			*msg = m->data;
			free(m);			
		}else if(msgque->closing){
			ret = -1;
			errno = MSGQUE_CLOSE;
		}		
	}while(0);
	kn_mutex_unlock(msgque->mtx);	
	return ret;
}

void kn_close_reader(kn_msgque_reader_t reader){
	struct msg *m;
	while((m = (struct msg*)kn_list_pop(&reader->readbuff)) != NULL){
		if(m->fn_destroy) m->fn_destroy(m->data);
		free(m);
	}
	refobj_dec((refobj*)reader->msgque);
	kn_condition_destroy(reader->cond);
	free(reader);	
}


void kn_close_writer(kn_msgque_writer_t writer){
	struct msg *m;
	while((m = (struct msg*)kn_list_pop(&writer->writebuff)) != NULL){
		if(m->fn_destroy) m->fn_destroy(m->data);
		free(m);
	}
	refobj_dec((refobj*)writer->msgque);
	free(writer);		
}



