#ifndef _VERIFYS_H
#define _VERIFYS_H
/*
 *  验证服务
*/ 
#include "core/asynnet/msgdisp.h"
#include "core/thread.h"
#include "core/db/asyndb.h"
#include "core/kn_string.h"
#include "core/asynnet/asyncall.h"

typedef struct verfiyservice
{
	volatile uint8_t stop;
	thread_t    thd;
	msgdisp_t   msgdisp;
	asyndb_t    dbredis;
}*verfiyservice_t;

int32_t start_verifyservice();
void    stop_verifyservice();

int32_t verify_login(asyncall_context_t,fn_asyncall_result,string_t acctname,string_t passwd);
void verify_reconnect();



#endif
