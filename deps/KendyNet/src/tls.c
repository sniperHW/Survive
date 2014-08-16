#include "tls.h"
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*struct tls_st
{
    void *tls_val;
    TLS_DESTROY_FN destroy_fn;
};

static pthread_key_t g_tls_key;
static pthread_once_t g_tls_key_once = PTHREAD_ONCE_INIT;

static void tls_destroy_fn(void *ud)
{
    struct tls_st *thd_tls = (struct tls_st*)ud;
    uint16_t i = 0;
    for(; i < MAX_TLS_SIZE;++i)
        if(thd_tls[i].tls_val && thd_tls[i].destroy_fn)
            thd_tls[i].destroy_fn(thd_tls[i].tls_val);
    free(ud);
}

static void tls_once_routine(){
    pthread_key_create(&g_tls_key,tls_destroy_fn);
}
*/

/*int32_t tls_create(uint16_t key,TLS_DESTROY_FN fn)
{
    if(key >= MAX_TLS_SIZE) return -1;
    pthread_once(&g_tls_key_once,tls_once_routine);
    struct tls_st *thd_tls = (struct tls_st *)pthread_getspecific(g_tls_key);
    thd_tls[key].destroy_fn = fn;
    return 0;
}*/

static __thread void* all_tls[MAX_TLS_SIZE];


void* tls_get(uint16_t key)
{
    if(key >= MAX_TLS_SIZE) return NULL;
    return all_tls[key];
    /*pthread_once(&g_tls_key_once,tls_once_routine);
    struct tls_st *thd_tls = (struct tls_st *)pthread_getspecific(g_tls_key);
    if(unlikely(!thd_tls)){ 
		thd_tls = calloc(1,sizeof(struct tls_st)*MAX_TLS_SIZE);
		pthread_setspecific(g_tls_key,thd_tls);
		return NULL;
	}
    return thd_tls[key].tls_val;*/
}

int32_t  tls_set(uint16_t key,void *ud/*,TLS_DESTROY_FN fn*/)
{
    if(key >= MAX_TLS_SIZE) return -1;
    all_tls[key] = ud;
    /*pthread_once(&g_tls_key_once,tls_once_routine);
    struct tls_st *thd_tls = (struct tls_st *)pthread_getspecific(g_tls_key);
    if(unlikely(!thd_tls)){ 
		thd_tls = calloc(1,sizeof(struct tls_st)*MAX_TLS_SIZE);
		pthread_setspecific(g_tls_key,thd_tls);
	}
    if(unlikely(thd_tls[key].tls_val && thd_tls[key].destroy_fn))
		thd_tls[key].destroy_fn(thd_tls[key].tls_val);
	thd_tls[key].tls_val = ud;
	thd_tls[key].destroy_fn = fn;
	*/
	return 0;	
}

