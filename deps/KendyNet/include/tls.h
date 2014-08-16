#ifndef _TLS_H
#define _TLS_H

#include <stdint.h>
#include <pthread.h>

#define MAX_TLS_SIZE 4096

void*    tls_get(uint16_t key);

int32_t  tls_set(uint16_t key,void*);

#endif
