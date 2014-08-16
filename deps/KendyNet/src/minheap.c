#include "minheap.h"

minheap_t minheap_create(int32_t size,int8_t (*less)(struct heapele*l,struct heapele*r))
{
	minheap_t m = calloc(1,sizeof(*m));// + (size * sizeof(struct heapele*)));
	m->data = (struct heapele**)calloc(size,sizeof(struct heapele*));
	m->size = 0;
	m->max_size = size;
	m->less = less;
	return m;
}

void minheap_destroy(minheap_t *m)
{
	free(*m);
	*m = NULL;
}

void minheap_clear(minheap_t m,clear_fun f)
{
	uint32_t i;
	for(i = 1; i <= m->size; ++i)
	{
		if(f)
			f(m->data[i]);
		m->data[i]->index = 0;
	}
	m->size = 0;
}
