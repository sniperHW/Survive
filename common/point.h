#ifndef _POINT_H
#define _POINT_H
#include <stdint.h>
#include <math.h>
typedef struct 
{
	int32_t x;
	int32_t y;
}point2D;

static inline uint64_t cal_distance_2D(point2D *pos1,point2D *pos2)
{
	uint64_t tmp1 = abs(pos1->x - pos2->x);
	tmp1 *= tmp1;
	uint64_t tmp2 = abs(pos1->y - pos2->y);
	tmp2 *= tmp2;
	return (uint64_t)sqrt(tmp1 + tmp2);
}

#endif
