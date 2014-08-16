#include "spinlock.h"
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
//#include "sync.h"

spinlock_t spin_create()
{
	spinlock_t sp = malloc(sizeof(*sp));
	sp->lock_count = 0;
#ifdef _WIN
	sp->owner.p = NULL;
	sp->owner.x = 0;	
#else
	sp->owner = 0;
#endif	
	return sp;
}

void spin_destroy(spinlock_t sp)
{
	free(sp);
}



