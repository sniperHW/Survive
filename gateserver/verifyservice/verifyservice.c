#include "verifyservice.h"
#include "common/tls_define.h"
#include "core/tls.h"
#include "hiredis.h"


static verfiyservice_t g_verifyservice = NULL;

//static asyndb_t db2redis = NULL;

string_t g_redisip = NULL;
int32_t  g_redisport = 0;

static void *service_main(void *ud){
	printf("verifyservice启动运行\n");
    while(!g_verifyservice->stop){
        msg_loop(g_verifyservice->msgdisp,50);
    }
    return NULL;
}

int32_t start_verifyservice(){	
	g_verifyservice= calloc(1,sizeof(*g_verifyservice));
	g_verifyservice->msgdisp = new_msgdisp(NULL,0);
	g_verifyservice->thd = create_thread(THREAD_JOINABLE);
	g_verifyservice->dbredis = new_asyndb(db_redis,to_cstr(g_redisip),g_redisport);
	thread_start_run(g_verifyservice->thd,service_main,NULL);
	return 0;
}

void stop_verifyservice(){
	g_verifyservice->stop = 1;
	thread_join(g_verifyservice->thd);
}

struct login_context
{
	asyncall_context_t asyncontext;
	string_t           passwd;
};

void db_login_callback(struct db_result *result)
{
	struct login_context *lcontext = (struct login_context*)result->ud;
	asyncall_context_t context = lcontext->asyncontext;
	redisReply *r = (redisReply*)result->result_set;
	void *ret = NULL;
	if(strcmp(r->str,to_cstr(lcontext->passwd)) == 0)
		ret = (void*)1;
	free(lcontext);
	free_dbresult(result);	
	ASYNRETURN(context,ret);
}

void verify_asyncall_login(asyncall_context_t context,void **param)
{
	printf("verify_asyncall_login\n");
	char req[256];
	snprintf(req,256,"get %s",to_cstr((string_t)param[0]));	
	//发出到redis的验证
	struct login_context *lcontext = calloc(1,sizeof(*lcontext));
	lcontext->asyncontext = context;
	lcontext->passwd = (string_t)param[1];
	if(0 != g_verifyservice->dbredis->asyn_request(g_verifyservice->dbredis,
	                          new_dbrequest(req,db_login_callback,lcontext,g_verifyservice->msgdisp)))
	{
		free(lcontext);
		ASYNRETURN(context,NULL);
	}
}

int32_t verify_login(asyncall_context_t context,string_t acctname,string_t passwd)
{
	msgdisp_t from = (msgdisp_t)tls_get(MSGDISCP_TLS);
	msgdisp_t to = g_verifyservice->msgdisp;
	return ASYNCALL2(from,to,verify_asyncall_login,context,acctname,passwd);
}
