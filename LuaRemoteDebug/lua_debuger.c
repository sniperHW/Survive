#include "lua_debuger.h"

static kn_proactor_t d_proactor = NULL;
static kn_stream_server_t d_stream_server = NULL;

int ldebuger_init(){
	if(d_proactor || d_stream_server) 
		return -1;
		
	d_proactor = kn_new_proactor();	
	d_stream_server = kn_new_stream_server(d_proactor,NULL,NULL);
	return 0;
}


