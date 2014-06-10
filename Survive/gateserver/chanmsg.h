#ifndef _CHANMSG_H
#define _CHANMSG_H
#include <stdint.h>
#include "wpacket.h"
#include "kn_stream_conn.h"
enum{
	FORWARD_GAME,
	FORWARD_GROUP,
	NEWCLIENT,
};

struct chanmsg{
	uint16_t msgtype;
};

struct chanmsg_newclient{
	chanmsg   chanmsg;
	kn_stream_conn_t conn;
}

static inline void chanmsg_newclient_destroy(void *msg){
	struct chanmsg_newclient *_msg = (struct chanmsg_newclient*)msg;
	if(_msg->conn){
		kn_stream_conn_close(_msg->conn);
	}
	free(msg);
}

struct chanmsg_forward_game{
	chanmsg   chanmsg;
	wpacket_t wpk;
	ident     game;
};

static inline void chanmsg_forward_game_destroy(void *msg){
	struct chanmsg_forward_game *_msg = (struct chanmsg_forward_game*)msg;
	if(_msg->wpk){
		wpk_destroy(_msg->wpk);
	}
	free(msg);
}

struct chanmsg_forward_group{
	chanmsg chanmsg;
	wpacket_t wpk;
};

static inline void chanmsg_forward_group_destroy(void *msg){
	struct chanmsg_forward_group *_msg = (struct chanmsg_forward_group*)msg;
	if(_msg->wpk){
		wpk_destroy(_msg->wpk);
	}
	free(msg);	
}




#endif