#ifndef _KN_SOCKADDR_H
#define _KN_SOCKADDR_H
#include "kn_common_include.h"
typedef struct kn_sockaddr{
	int  addrtype;
	union{
		struct sockaddr_in  in;   //for ipv4 
		struct sockaddr_in6 in6;  //for ipv6
		struct sockaddr_un  un;   //for unix domain
	};
}kn_sockaddr;


static inline int kn_addr_init_in(kn_sockaddr *addr,const char *ip,uint32_t port){
	
	memset((void*)addr,0,sizeof(*addr));
	addr->addrtype = AF_INET;
	addr->in.sin_family = AF_INET;
	addr->in.sin_port = htons(port);
	if(inet_pton(AF_INET,ip,&addr->in.sin_addr) < 0)
	{
		return -errno;
	}
	return 0;
}

static inline int kn_addr_init_un(kn_sockaddr *addr,const char *path){
	
	memset((void*)addr,0,sizeof(*addr));
	addr->addrtype = AF_LOCAL;
	addr->un.sun_family = AF_LOCAL;
	strncpy(addr->un.sun_path,path,sizeof(addr->un.sun_path)-1);
	return 0;
}


#endif
