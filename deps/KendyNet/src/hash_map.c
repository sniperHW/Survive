#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include "hash_map.h"

hash_map_t hash_map_create(uint32_t slot_size,hash_func hash_function,
						   key_cmp key_cmp_function,hash_func snd_hash_function)
{
	assert(hash_function);
	assert(key_cmp_function);	
	hash_map_t h = (hash_map_t)malloc(sizeof(*h));
	if(!h) return NULL;
	h->slot_size = slot_size;
	h->size = 0;
	h->hash_function = hash_function;
	h->snd_hash_function = snd_hash_function;
	h->key_cmp_function = key_cmp_function;
	kn_dlist_init(&h->dlink);
	h->slots = calloc(1,sizeof(*h->slots)*slot_size);
	return h;
}


static inline int slot_insert(hash_slot *slot,hash_node *n,key_cmp key_cmp_function,
							  uint64_t hash_code,uint64_t snd_hash_code)
{
	if(slot->size == SLOT_CAP) return -1;
	int i = 0;
	for(; i < SLOT_CAP && slot->nodes[i]; ++i){
		if(hash_code == slot->nodes[i]->hash_code &&
		   snd_hash_code == slot->nodes[i]->snd_hash_code &&
		   key_cmp_function(n->key,slot->nodes[i]->key) == 0)
		   return -2;
	}
	slot->nodes[i] = n;
	slot->size++;
	return 0;		
}

static inline hash_node* slot_find(hash_slot *slot,void *key,key_cmp key_cmp_function,
								   uint64_t hash_code,uint64_t snd_hash_code)
{
	if(slot->size == 0) return NULL;
	int i = 0;
	for(; i < SLOT_CAP && slot->nodes[i]; ++i){
		if(hash_code == slot->nodes[i]->hash_code &&
		   snd_hash_code == slot->nodes[i]->snd_hash_code &&
		   key_cmp_function(key,slot->nodes[i]->key) == 0){
		   return slot->nodes[i];		
	   }
	}
	return NULL;	
}


static inline hash_node* slot_remove(hash_slot *slot,void *key,key_cmp key_cmp_function,
									 uint64_t hash_code,uint64_t snd_hash_code)
{
	if(slot->size == 0) return NULL;
	hash_node *n = NULL;
	int i = 0;
	for(; i < SLOT_CAP && slot->nodes[i]; ++i){
		if(hash_code == slot->nodes[i]->hash_code &&
		   snd_hash_code == slot->nodes[i]->snd_hash_code &&
		   key_cmp_function(key,slot->nodes[i]->key) == 0){
		   n = slot->nodes[i];
		   break;
	   }		
	}
	if(!n) return NULL;	
	if(i != slot->size-1){
		//不是最后一个元素,将最后一个元素的位置交换到要删除的位置		
		slot->nodes[i] = slot->nodes[slot->size-1];		
	}
	n->hash_code = n->snd_hash_code = 0;	
	--slot->size;
	slot->nodes[slot->size] = NULL;//将末尾置空
	return n;
}


static inline int expand(hash_map_t h){
	free(h->slots);
	h->slot_size *= 2;
	h->slots = calloc(1,sizeof(*h->slots)*h->slot_size);
	if(!h->slots) return -1;
	
	if(kn_dlist_empty(&h->dlink)) return 0;
	hash_node *cur = (hash_node*)kn_dlist_begin(&h->dlink);
	hash_node *end = (hash_node*)kn_dlist_end(&h->dlink);
	while(cur != end){		
		uint64_t index = cur->hash_code % h->slot_size;
		assert(slot_insert(&h->slots[index],cur,h->key_cmp_function,cur->hash_code,cur->snd_hash_code) == 0);
		cur = (hash_node*)cur->node.next;
	}
	printf("expand\n");	
	return 0;
}

int hash_map_insert(hash_map_t h,hash_node* n)
{
	uint64_t hash_code = h->hash_function(n->key);
	uint64_t snd_hash_code = 0;
	if(h->snd_hash_function) h->snd_hash_function(n->key);
	uint64_t index = hash_code % h->slot_size;
	int ret = slot_insert(&h->slots[index],n,h->key_cmp_function,hash_code,snd_hash_code);
	do{
		if(ret == 0){
			break;
		}else if(ret == -1){
			//扩展空间
			if(expand(h) != 0)
				return -2;
			index = hash_code % h->slot_size;
			assert(slot_insert(&h->slots[index],n,h->key_cmp_function,hash_code,snd_hash_code) == 0);
			break;		
		}else{
			return -1;
		}
	}while(0);
	n->hash_code = hash_code;
	n->snd_hash_code = snd_hash_code;
	h->size++;
	kn_dlist_push(&h->dlink,(kn_dlist_node*)n);
	return 0;
}

hash_node*     hash_map_remove(hash_map_t h,void *key)
{
	uint64_t hash_code = h->hash_function(key);
	uint64_t snd_hash_code = 0;
	if(h->snd_hash_function) h->snd_hash_function(key);
	uint64_t index = hash_code % h->slot_size;
	hash_node *n = slot_remove(&h->slots[index],key,h->key_cmp_function,hash_code,snd_hash_code);
	
	if(n){
		kn_dlist_remove((kn_dlist_node*)n);
		h->size--;
	}
	return n;
}


hash_node*     hash_map_find(hash_map_t h,void* key)
{
	uint64_t hash_code = h->hash_function(key);
	uint64_t snd_hash_code = 0;
	if(h->snd_hash_function) h->snd_hash_function(key);
	uint64_t index = hash_code % h->slot_size;
	return 	slot_find(&h->slots[index],key,h->key_cmp_function,hash_code,snd_hash_code);
} 

void hash_map_destroy(hash_map_t h,hash_destroy ondestroy)
{
	hash_node *n = (hash_node*)kn_dlist_pop(&h->dlink);
	while(n){
		ondestroy(n);
		n = (hash_node*)kn_dlist_pop(&h->dlink);
	}
	free(h->slots);
	free(h);
}
