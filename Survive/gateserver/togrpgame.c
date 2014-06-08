#include "togrpgame.h"
#include "chanmsg.h"
#include "kn_stream_conn.h"

static __thread togrpgame  t_togrpgame = NULL;

//处理来group和game的消息
static int on_packet(kn_stream_conn_t con,rpacket_t rpk){
	if(con == t_togrpgame->togroup){
		//from group
	}else{
		//from game
	}
}

//处理来自channel的消息
static void on_channel_msg(kn_channel_t chan, kn_channel_t from,void *msg,void *_)
{
	(void)_;
	if(((struct chanmsg*)msg)->msgtype == FORWARD_GAME){
		struct chanmsg_forward_game *_msg = (struct chanmsg_forward_game*)msg;
		kn_stream_conn_t conn = cast2_kn_stream_conn(_msg->game);
		if(conn){
			kn_stream_conn_send(conn,_msg->wpk);
			_msg->wpk = NULL;
		}
	}else if(((struct chanmsg*)msg)->msgtype == FORWARD_GROUP){
		struct chanmsg_forward_group *_msg = (struct chanmsg_forward_group*)msg;
		if(t_togrpgame->togroup){
			kn_stream_conn_send(t_togrpgame->togroup,_msg->wpk);
			_msg->wpk = NULL;
		}
	}
}