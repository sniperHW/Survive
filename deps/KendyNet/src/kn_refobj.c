#include "kn_refobj.h"
#include "kn_time.h"

atomic_32_t g_ref_counter = 0;

void refobj_init(refobj *r,void (*destructor)(void*))
{
	r->destructor = destructor;
	r->high32 = kn_systemms();
	r->low32  = (uint32_t)(ATOMIC_INCREASE(&g_ref_counter));
	r->refcount = 1;
}
