#ifndef _IDMGR_H
#define _IDMGR_H
#include <stdint.h>
#include "kn_list.h"

typedef struct idnode
{
	kn_list_node    node;	
	int32_t  id;
}idnode;


typedef struct idmgr{
	kn_list  idpool;
	uint32_t beginid;
	uint32_t endid;
}*idmgr_t;

static inline idmgr_t new_idmgr(int32_t beginid,int32_t endid)
{
	if(beginid < 0 || endid < 0 || beginid > endid)
		return NULL;
	idmgr_t _idmgr = calloc(1,sizeof(*_idmgr));
	_idmgr->beginid = beginid;
	_idmgr->endid = endid;
	kn_list_init(&_idmgr->idpool);
	for(int32_t i = beginid;i <= endid; ++i){
		idnode *id = calloc(1,sizeof(*id));
		id->id = i;
		kn_list_pushback(&_idmgr->idpool,(kn_list_node*)id);
	}
	return _idmgr;	
}

static inline void destroy_idmgr(idmgr_t _idmgr)
{
	idnode *id;
	while((id = (idnode*)kn_list_pop(&_idmgr->idpool))!= NULL)
		free(id);
	free(_idmgr);
}

static inline int32_t get_id(idmgr_t _idmgr)
{
	idnode *id = (idnode*)kn_list_pop(&_idmgr->idpool);
	if(!id) return -1;
	int32_t ret = id->id;
	free(id);
	return ret;
}

static inline void release_id(idmgr_t _idmgr,int32_t id)
{
	if(id >= _idmgr->beginid && id <= _idmgr->endid)
	{
		idnode *_idnode = calloc(1,sizeof(*_idnode));
		_idnode->id = id;
		kn_list_pushback(&_idmgr->idpool,(kn_list_node*)_idnode);
	}
}



#endif
