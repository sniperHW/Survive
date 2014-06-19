#ifndef _CHANMSG_H
#define _CHANMSG_H
#include <stdint.h>
#include "wpacket.h"
#include "kn_stream_conn.h"
enum{
	FORWARD_GAME,
	FORWARD_GROUP,
	NEWCLIENT,
	RPACKET,
};

struct chanmsg{
	uint16_t msgtype;
};

struct chanmsg_newclient{
	struct chanmsg   chanmsg;
	kn_stream_conn_t conn;
};

static inline void chanmsg_newclient_destroy(void *msg){
	struct chanmsg_newclient *_msg = (struct chanmsg_newclient*)msg;
	if(_msg->conn){
		kn_stream_conn_close(_msg->conn);
	}
	free(msg);
}

struct chanmsg_forward_game{
	struct chanmsg   chanmsg;
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
	struct chanmsg chanmsg;
	wpacket_t wpk;
};

static inline void chanmsg_forward_group_destroy(void *msg){
	struct chanmsg_forward_group *_msg = (struct chanmsg_forward_group*)msg;
	if(_msg->wpk){
		wpk_destroy(_msg->wpk);
	}
	free(msg);	
}

struct chanmsg_rpacket{
	struct chanmsg chanmsg;
	rpacket_t rpk;
};

static inline void chanmsg_rpacket_destroy(void *msg){
	struct chanmsg_rpacket *_msg = (struct chanmsg_rpacket*)msg;
	if(_msg->rpk){
		rpk_destroy(_msg->rpk);
	}
	free(msg);	
}




#endif
