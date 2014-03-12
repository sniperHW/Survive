#include "avatar.h"
#include "core/tls.h"
#include "common/tls_define.h"
#include "core/common_define.h"
//#include "superservice/superservice.h"

//extern superservice_t g_superservice;

//player_cmd_handler player_handlers[MAX_CMD] = {0}


/*
*super_fn_destroy的执行可能会修改由superservice管理的某些全局数据，
*所以如果,最后一个释放引用计数的执行过程不在superservice中的话,需要
*将super_fn_destroy发给superservice执行
*/

/*void player_destroyer(player_t splayer)
{
	msgdisp_t disp = (msgdisp_t)tls_get(MSGDISCP_TLS);
	if(disp == g_superservice->msgdisp)
	{
		//在superservice中，直接执行销毁过程
		splayer->player_fn_destroy((void*splayer));
	}else
	{
		//否则,发给消息给msgdisp_t,让它来执行
		msg_do_function_t msg = calloc(1,sizeof(*msg));
		MSG_TYPE(msg) = MSG_DO_FUNCTION;
		MSG_USRPTR(msg) = (void*)splayer;
		msg->fn_function = splayer->player_fn_destroy;
		if(0 != push_msg(super_msgdisp,msg))
		{
			//发送到superservice失败，记录日志
			free(msg);
		}
	}
}*/