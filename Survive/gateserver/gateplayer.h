#ifndef _GATEPLAYER_H
#define _GATEPLAYER_H

#include "kn_string.h"
#include "kn_ref.h"
#include "common/agentsession.h"

typedef struct agentplayer{
	kn_ref           ref;
	agentsession     agentsession;
	kn_stream_conn_t toclient;
	ident            togame;
	uint32_t         gameid;
	uint32_t         groupid;
	kn_string_t      actname;
}agentplayer,*agentplayer_t;

#endif