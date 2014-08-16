#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "kn_string.h"
#include "kn_refobj.h"
#include "kn_common_define.h"

typedef struct string_holder
{
	refobj    ref;
	char*     str;
	int32_t   len;
}*holder_t;


static void destroy_string_holder(void *arg)
{
	printf("destroy_string_holder\n");
	holder_t h = (holder_t)arg;
	free((void*)h->str);
	free(h);
}

static inline holder_t string_holder_create(const char *str,uint32_t len)
{
	holder_t h = calloc(1,sizeof(*h));
	if(strlen(str)+1 == len){	
		h->str = calloc(1,size_of_pow2(len));
		strncpy(h->str,str,len);
	}else{
		h->str = calloc(1,size_of_pow2(len+1));
		strncpy(h->str,str,len);
		h->str[len] = 0;
	}
	refobj_init(&h->ref,destroy_string_holder);
	return h;
}

static inline void string_holder_release(holder_t h)
{
	if(h) refobj_dec(&h->ref);
}

static inline void string_holder_acquire(holder_t h)
{
    if(h) refobj_inc(&h->ref);
}


#define MIN_STRING_LEN 64

struct kn_string
{
	holder_t holder;
	char str[MIN_STRING_LEN];
};


kn_string_t kn_new_string(const char *str)
{
	if(!str) return NULL;

	kn_string_t _str = calloc(1,sizeof(*_str));
	int32_t len = strlen(str)+1;
	if(len <= MIN_STRING_LEN)
		strncpy(_str->str,str,MIN_STRING_LEN);
	else
		_str->holder = string_holder_create(str,len);
	return _str;
}

void kn_release_string(kn_string_t s)
{
	if(s->holder) string_holder_release(s->holder);
	free(s);
}

const char *kn_to_cstr(kn_string_t s){
	if(s->holder) return s->holder->str;
	return s->str;
}

int32_t  kn_string_len(kn_string_t s)
{
	if(s->holder) return strlen(s->holder->str)+1;
	return strlen(s->str)+1;
}

void kn_string_copy(kn_string_t to,kn_string_t from,uint32_t n)
{
	if(n > kn_string_len(from)) return;
	if(n <= MIN_STRING_LEN)
	{
		if(to->holder){
			string_holder_release(to->holder);
			to->holder = NULL;
		}
		char *str = from->str;
		if(from->holder) str = from->holder->str;
		strncpy(to->str,str,n);
	}else
	{
		if(n == kn_string_len(from)){
			if(to->holder) string_holder_release(to->holder);
			string_holder_acquire(to->holder);
		}else if(n > kn_string_len(to)){
			if(to->holder) string_holder_release(to->holder);
			to->holder = string_holder_create(kn_to_cstr(from),n);	
		}else{
			strncpy(to->holder->str,kn_to_cstr(from),n);	
		}
	}
}

void kn_string_append(kn_string_t s,const char *cstr)
{
	if(!s || !cstr) return;
	int32_t len = kn_string_len(s) + strlen(cstr);
	if(len <= MIN_STRING_LEN)
		strcat(s->str,cstr);
	else
	{
		if(s->holder && len <= s->holder->len)
			strcat(s->holder->str,cstr);
		else{
			
			holder_t h = string_holder_create(kn_to_cstr(s),len*2);
			strcat(h->str,cstr);
			string_holder_release(s->holder);
			s->holder = h;
		}
	}
}
