#include "superservice/superservice.h"
#include "battleservice/battleservice.h"
#include "core/lua_util.h"

static volatile int8_t stop = 0;

static void stop_handler(int signo){
    stop = 1;
}

void setup_signal_handler()
{
	struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = stop_handler;
    sigaction(SIGINT, &act, NULL);
    sigaction(SIGTERM, &act, NULL);
}


int main()
{
	//从lua读取配置
	lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L,"config.lua")) {
		const char * error = lua_tostring(L, -1);
		lua_pop(L,1);
		printf("%s\n",error);
		return 0;
	}
	lua_getglobal(L,"config");
	luaObject_t config = create_luaObj(L,-1);

	//建立消息处理映射表
	build_super_cmd_handler();
	build_battle_cmd_handler();

	//先创建battleservice
	//再创建superservice
	//g_superservice = new_superservice();

	release_luaObj(config);
	lua_close(L);
	//while(stop == 0)
	//	sleep(1);

	//先关闭battleservice
	//destroy_superservice(&g_superservice);

	return 0;
}