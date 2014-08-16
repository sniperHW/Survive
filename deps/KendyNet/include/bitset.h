#ifndef _BITSET_H
#define _BIGSET_H

#include <stdint.h>


typedef struct bit_set
{
	uint32_t size;
	uint32_t bits[];
}*bit_set_t;

static inline bit_set_t new_bitset(uint32_t size)
{
	uint32_t _size = size % sizeof(uint32_t) == 0 ?
					 size/sizeof(uint32_t):size/sizeof(uint32_t)+1;
	bit_set_t bs = calloc(1,sizeof(*bs)+sizeof(uint32_t)*_size);
	bs->size = size;
	return bs;
}

static inline void del_bitset(bit_set_t bs)
{
	free(bs);
}

static inline void set_bit(struct bit_set *bs,uint32_t index)
{
	if(index <= bs->size){
		uint32_t b_index = index / (sizeof(uint32_t)*8);
		index %= (sizeof(uint32_t)*8);
		bs->bits[b_index] = bs->bits[b_index] | (1 << index);
	}
}

static inline void clear_bit(struct bit_set *bs,uint32_t index)
{
	if(index <= bs->size){
		uint32_t b_index = index / (sizeof(uint32_t)*8);
		index %= (sizeof(uint32_t)*8);
		bs->bits[b_index] = bs->bits[b_index] & (~(1 << index));
	}
}

static inline uint8_t is_set(struct bit_set *bs,uint32_t index)
{
	if(index <= bs->size){
		uint32_t b_index = index / (sizeof(uint32_t)*8);
		index %= (sizeof(uint32_t)*8);
		return bs->bits[b_index] & (1 << index)?1:0;
	}else
		return 0;
}

#endif
