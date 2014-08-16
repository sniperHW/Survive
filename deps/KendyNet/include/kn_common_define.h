#ifndef _COMMON_DEFINE_H
#define _COMMON_DEFINE_H

#include <stdint.h>
#include "kn_list.h"


typedef struct
{
    kn_list_node      next;
    void*             ud;
	struct            iovec *iovec;
	int32_t           iovec_count;
}st_io;

#ifndef TEMP_FAILURE_RETRY
#define TEMP_FAILURE_RETRY(expression)\
	({ long int __result;\
	do __result = (long int)(expression);\
	while(__result == -1L&& errno == EINTR);\
	__result;})
#endif


#define MAX_UINT32 0xffffffff
#define likely(x) __builtin_expect(!!(x), 1)  
#define unlikely(x) __builtin_expect(!!(x), 0)

static inline int32_t is_pow2(uint32_t size){
	return !(size&(size-1));
}

static inline uint32_t size_of_pow2(uint32_t size)
{
    if(is_pow2(size)) return size;
	size = size-1;
	size = size | (size>>1);
	size = size | (size>>2);
	size = size | (size>>4);
	size = size | (size>>8);
	size = size | (size>>16);
	return size + 1;
}

static inline uint8_t get_pow2(uint32_t size)
{
	uint8_t pow2 = 0;
    if(!is_pow2(size)) size = (size << 1);
	while(size > 1){
		pow2++;
		size = size >> 1;
	}
	return pow2;
}



#endif
