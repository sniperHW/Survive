#ifndef _CHANMSG_H
#define _CHANMSG_H
#include <stdint.h>
#include "wpacket.h"
enum{
	FORWARD_GAME,
	FORWARD_GROUP,
};

struct chanmsg{
	uint16_t msgtype;
};

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