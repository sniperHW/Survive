#ifndef _KENDYNET_H
#define _KENDYNET_H

#include "kn_common_include.h"
#include "kn_common_define.h"
#include "kn_sockaddr.h"
#include "kn_time.h"

typedef struct handle* handle_t;
typedef void* engine_t;


engine_t kn_new_engine();
void     kn_release_engine(engine_t);
int      kn_engine_run(engine_t);
void     kn_stop_engine(engine_t);

handle_t kn_new_sock(int domain,int type,int protocal);
int      kn_close_sock(handle_t);

int      kn_sock_listen(engine_t,
						handle_t,
						kn_sockaddr*,
						void (*cb_accept)(handle_t,void*),
						void*);
						
int      kn_sock_connect(engine_t,
						 handle_t,
						 kn_sockaddr *remote,
						 kn_sockaddr *local,
						 void (*cb_connect)(handle_t,int,void*,kn_sockaddr*),
						 void*);

int      kn_sock_associate(handle_t,
						   engine_t,
						   void (*cb_ontranfnish)(handle_t,st_io*,int,int),
						   void (*destry_stio)(st_io*));

int      kn_sock_send(handle_t,st_io*);
int      kn_sock_recv(handle_t,st_io*);
void     kn_sock_setud(handle_t,void*);
void*    kn_sock_getud(handle_t);
int      kn_sock_fd(handle_t);
engine_t kn_sock_engine(handle_t);
kn_sockaddr* kn_sock_addrlocal(handle_t);
kn_sockaddr* kn_sock_addrpeer(handle_t);



#endif
