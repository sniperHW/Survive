#include "common/cmd.h"
#include "avatar.h"
#include "battleservice/battleservice.h"
#include "core/lua_util.h"
#include "superservice.h"
#include "core/log.h"
#include "core/asynnet/msgdisp.h"

superservice_t g_superservice = NULL;
static cmd_handler_t super_cmd_handlers[MAX_CMD] = {NULL};

static rbtree_t g_player_tree = NULL;

static int32_t ply_cmp_function(void *key1,void *key2)
{
	string_t name1 = (string_t)key1;
	string_t name2 = (string_t)key2;
	return (int32_t)strcmp(to_cstr(name1),to_cstr(name2));
}

player_t find_player_by_actname(const char* actname)
{
	string_t key = new_string(actname);
	struct rbnode *node = rbtree_find(g_player_tree,(void*)key);
	player_t ply = NULL;
	if(node) ply = (player_t)(((char*)node)-sizeof(struct refbase));
	release_string(key);
	return ply;
}

void remove_player(player_t ply){
	rbtree_erase(&ply->_rbnode);
	player_decref(ply);
}

int32_t insert_player(player_t ply)
{
	ply->_rbnode.key = ply->_actname;
	return (int32_t)rbtree_insert(g_player_tree,&ply->_rbnode);
}

int32_t send2gate(wpacket_t wpk)
{
	if(!g_superservice || !wpk) return -1;
	if(!is_vaild_ident(TO_IDENT(g_superservice->togate))) return -1;
	return asyn_send(g_superservice->togate,wpk);
}

void super_connect(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
    disp->bind(disp,0,sock,65536,1,3*1000,0);//由系统选择poller
}

void super_connected(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port)
{
	g_superservice->togate = sock;
}

void super_disconnected(msgdisp_t disp,sock_ident sock,const char *ip,int32_t port,uint32_t err)
{
	if(EQ_IDENT(g_superservice->togate,sock))
		MAKE_EMPTY_IDENT(g_superservice->togate);
}

int32_t super_processpacket(msgdisp_t disp,rpacket_t rpk)
{
	uint16_t cmd = rpk_peek_uint16(rpk);
	if(cmd >= CMD_C2GAME && cmd <= CMD_C2GAME_END)
	{
		if(cmd > CMD_C2BATTLE && cmd < CMD_C2BATTLE_END)
		{
			//将消息转发到battleservice
			uint8_t battleserid = reverse_read_uint8(rpk);
			battleservice_t battle = get_battle_by_index(battleserid);
			if(battle && 0 == send_msg(NULL,battle->msgdisp,(msg_t)rpk))
				return 0;//不销毁rpk,由battleservice负责销毁*/							
		}else{
			ident _ident= reverse_read_ident(rpk);
			player_t ply = (player_t)cast_2_refbase(_ident);
			if(ply && ply->_status == normal){
				if(super_cmd_handlers[cmd]){
					rpk_read_uint16(rpk);//丢弃cmd
					call_handler(super_cmd_handlers[cmd],rpk,ply);
				}else{
					SYS_LOG(LOG_INFO,"unknow cmd:%d\n",cmd);
				}
			}
			if(ply) ref_decrease((struct refbase*)ply);	
		}		
	}
    return 1;
}

static void reg_super_cmd_handler(uint16_t cmd,cmd_handler_t handler)
{
	if(cmd < MAX_CMD) super_cmd_handlers[cmd] = handler;
}

void start_superservice()
{
	g_superservice = calloc(1,sizeof(*g_superservice));
}

