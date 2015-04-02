#ifndef _IDMGR_H
#define _IDMGR_H
#include <stdint.h>
#include <assert.h>
#include "bitset.h"


typedef struct idmgr{
	uint32_t ridx;
	uint32_t widx;
	uint32_t size;
	uint32_t cap;
	uint32_t beginid;
	uint32_t endid;
#ifdef _DEBUG	
	bit_set_t idset;
#endif
	uint32_t array[0];
}*idmgr_t;

static inline idmgr_t new_idmgr(uint32_t beginid,uint32_t endid)
{
	if(beginid > endid)
		return NULL;
	uint32_t cap = endid - beginid + 1;
	idmgr_t _idmgr = calloc(1,sizeof(*_idmgr) + sizeof(uint32_t)*cap);	
	_idmgr->beginid = beginid;
	_idmgr->endid = endid;
	_idmgr->cap = _idmgr->size = cap;
	_idmgr->ridx = _idmgr->widx = 0;
#ifdef _DEBUG		
	_idmgr->idset = new_bitset(cap);
#endif
	uint32_t c = 0;
	uint32_t i = beginid;
	for(;i <= endid; ++i,++c){
		_idmgr->array[c] = i;
#ifdef _DEBUG			
		set_bit(_idmgr->idset,c);
#endif		
	}	
	return _idmgr;	
}

static inline void destroy_idmgr(idmgr_t _idmgr)
{
#ifdef _DEBUG		
	del_bitset(_idmgr->idset);
#endif
	free(_idmgr);
}

static inline int32_t get_id(idmgr_t _idmgr,uint32_t *id)
{
	if(!id || _idmgr->size == 0) return -1;
	*id = _idmgr->array[_idmgr->ridx];
	_idmgr->size--;
	_idmgr->ridx = (_idmgr->ridx + 1) % _idmgr->cap;
#ifdef _DEBUG		
	clear_bit(_idmgr->idset,*id-_idmgr->beginid);
#endif	
	return 0;
}

static inline int32_t release_id(idmgr_t _idmgr,int32_t id)
{
	if(id >= _idmgr->beginid && id <= _idmgr->endid && _idmgr->size < _idmgr->cap)
	{
#ifdef _DEBUG			
		if(is_set(_idmgr->idset,id - _idmgr->beginid)){
			assert(0);
			return -1;
		}
		set_bit(_idmgr->idset,id - _idmgr->beginid);	
#endif
		_idmgr->array[_idmgr->widx] = id;
		_idmgr->size++;
		_idmgr->widx = (_idmgr->widx + 1) % _idmgr->cap;
		return 0;		
	}
	return -1;
}





/*#include "kn_list.h"

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
*/


#endif
