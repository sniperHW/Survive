#include "gamedb.h"
#include "core/common_hash_function.h"

static asyndb_t *g_asyndbs = NULL;
static uint8_t   g_dbcount = 0;

int32_t init_gamedb_module(){
	
	
	return 0;
}

int32_t gamedb_request(player_t ply,db_request_t request)
{
	if(ply){
		//根据actname计算hash值,将请求分布到不同的数据库中
		const char *actname = to_cstr(ply->_actname);
		uint64_t hashcode = burtle_hash((uint8_t*)actname,strlen(actname),0);
		uint64_t dbindex = hashcode%(g_dbcount-1);
		return g_asyndbs[dbindex]->request(g_asyndbs[dbindex],request);
	}else{
		return 	g_asyndbs[g_dbcount-1]->request(g_asyndbs[g_dbcount-1],request);
		
	}	
}
