#include "kn_time.h"

pthread_key_t g_systime_key;
pthread_once_t g_systime_key_once = PTHREAD_ONCE_INIT;
