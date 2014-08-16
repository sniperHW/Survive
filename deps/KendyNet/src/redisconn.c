#include "kendynet_private.h"
#include "redisconn.h"

enum{
	REDIS_CONNECTING = 1,
	REDIS_ESTABLISH,
	REDIS_CLOSE,
};

void kn_redisDisconnect(redisconn_t rc);

static void redisLibevRead(redisconn_t rc){
    redisAsyncHandleRead(rc->context);
}

static void redisLibevWrite(redisconn_t rc){
    redisAsyncHandleWrite(rc->context);
}

typedef void (*redis_cb)(redisconn_t,redisReply*,void *pridata);

struct privst{
	kn_dlist_node node;
	redisconn_t rc;
	void*       privdata;
	void (*cb)(redisconn_t,redisReply*,void *pridata);
};

static void destroy_redisconn(redisconn_t rc){
		printf("destroy_redisconn\n");
		kn_dlist_node *node;
		while((node = kn_dlist_pop(&rc->pending_command))){
			struct privst *pri = ((struct privst*)node);
			pri->cb(rc,NULL,pri->privdata);
			free(node);	
		}
		free(rc);	
}

void kn_redisDisconnect(redisconn_t rc);

static void redis_on_active(handle_t s,int event){
	redisconn_t rc = (redisconn_t)s;
	do{
		if(rc->comm_head.status == REDIS_CONNECTING){
			int err = 0;
			socklen_t len = sizeof(err);
			if (getsockopt(rc->comm_head.fd, SOL_SOCKET, SO_ERROR, &err, &len) == -1) {
				rc->cb_connect(NULL,-1,rc->comm_head.ud);
				kn_redisDisconnect(rc);
				break;
			}
			if(err){
				errno = err;
				rc->cb_connect(NULL,errno,rc->comm_head.ud);
				kn_redisDisconnect(rc);
				break;
			}
			//connect success  
			rc->comm_head.status = REDIS_ESTABLISH;
			rc->cb_connect(rc,0,rc->comm_head.ud);			
		}else{
			if(event & (EPOLLERR | EPOLLHUP)){
				kn_redisDisconnect(rc);	
				break;
			}
			if(event & (EPOLLRDHUP | EPOLLIN)){
				redisLibevRead(rc);
			}
			if(event & EPOLLOUT){
				redisLibevWrite(rc);
			}
		}
	}while(0);
	
	if(rc->comm_head.status == REDIS_CLOSE){
		destroy_redisconn(rc);
	}	
}

static void redisAddRead(void *privdata){
	redisconn_t con = (redisconn_t)privdata;
	int events = con->events | EPOLLIN | EPOLLRDHUP;
	if(con->events == 0)
		kn_event_add(con->e,(handle_t)con,events);
	else
		kn_event_mod(con->e,(handle_t)con,events);
	con->events = events;	
}

static void redisDelRead(void *privdata) {
	redisconn_t con = (redisconn_t)privdata;
	int events = con->events & (~EPOLLIN);
	kn_event_mod(con->e,(handle_t)con,events);
	con->events = events;
}

static void redisAddWrite(void *privdata) {
	redisconn_t con = (redisconn_t)privdata;
	int events = con->events | EPOLLOUT;
	if(con->events == 0){
		kn_event_add(con->e,(handle_t)con,events);
	}else
		kn_event_mod(con->e,(handle_t)con,events);
	con->events = events;
}

static void redisDelWrite(void *privdata) {
	redisconn_t con = (redisconn_t)privdata;
	int events = con->events & (~EPOLLOUT);
	kn_event_mod(con->e,(handle_t)con,events);
	con->events = events;
}

static void redisCleanup(void *privdata) {
    redisconn_t con = (redisconn_t)privdata;
    if(con){
		if(con->comm_head.status == REDIS_ESTABLISH && con->cb_disconnected) 
			con->cb_disconnected(con,con->comm_head.ud);
		if(con->comm_head.status == REDIS_CONNECTING){
			destroy_redisconn(con);
		}else
			con->comm_head.status = REDIS_CLOSE;		
	} 
}

int kn_redisAsynConnect(engine_t p,
						const char *ip,unsigned short port,
						void (*cb_connect)(struct redisconn*,int err,void *ud),
						void (*cb_disconnected)(struct redisconn*,void *ud),
						void *ud)
{
	redisAsyncContext *c = redisAsyncConnect(ip, port);
    if(c->err) {
        printf("Error: %s\n", c->errstr);
        return -1;
    }
    redisconn_t con = calloc(1,sizeof(*con));
    con->context = c;
	con->comm_head.fd =  ((redisContext*)c)->fd;
	con->comm_head.on_events = redis_on_active;
	con->comm_head.type = KN_REDISCONN;
	con->comm_head.status = REDIS_CONNECTING; 
	con->cb_connect = cb_connect; 
	con->cb_disconnected = cb_disconnected;
	con->comm_head.ud = ud;
	con->e = p;
	kn_event_add(p,(handle_t)con,EPOLLIN | EPOLLOUT);
	con->events = EPOLLIN | EPOLLOUT;
	kn_dlist_init(&con->pending_command);	
    c->ev.addRead =  redisAddRead;
    c->ev.delRead =  redisDelRead;
    c->ev.addWrite = redisAddWrite;
    c->ev.delWrite = redisDelWrite;
    c->ev.cleanup =  redisCleanup;
    c->ev.data = con;		
	return 0; 											
}

static void kn_redisCallback(redisAsyncContext *c, void *r, void *privdata) {
	redisReply *reply = r;
	redisconn_t rc = ((struct privst*)privdata)->rc;
	redis_cb cb = ((struct privst*)privdata)->cb;
	if(cb){
		cb(rc,reply,((struct privst*)privdata)->privdata);
	}
	kn_dlist_remove((kn_dlist_node*)privdata);
	free(privdata);
}

int kn_redisCommand(redisconn_t rc,const char *cmd,
					void (*cb)(redisconn_t,redisReply*,void *pridata),void *pridata)
{
	struct privst *privst = NULL;
	if(cb){
		privst = calloc(1,sizeof(*privst));
		privst->rc = rc;
		privst->cb = cb;
		privst->privdata = pridata;
	}
	int status = redisAsyncCommand(rc->context, privst?kn_redisCallback:NULL,privst,cmd);
	if(status != REDIS_OK){
		if(privst) free(privst);
	}else{
		if(privst) kn_dlist_push(&rc->pending_command,(kn_dlist_node*)privst);
	}	
	return status;
}
					

void kn_redisDisconnect(redisconn_t rc){
	redisAsyncDisconnect(rc->context);
}

