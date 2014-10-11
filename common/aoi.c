#include "aoi.h"

#define BLOCK(M,X,Y) (&M->blocks[Y*M->x_size+X])

aoi_map *aoi_create(uint32_t max_aoi_objs,uint32_t _length,uint32_t radius,
					point2D *top_left,point2D *bottom_right)
{
	uint32_t length = abs(top_left->x - bottom_right->x);
	uint32_t width = abs(top_left->y - bottom_right->y);
	
	if(radius > length || radius > width) return NULL;
	if(radius < _length) radius = _length;
	
	uint32_t x_size = length % _length == 0 ? length/_length : length/_length + 1;
	uint32_t y_size = width % _length == 0 ? width/_length : width/_length + 1;
	
	aoi_map *m = calloc(1,x_size*y_size*sizeof(aoi_block)+sizeof(aoi_map));
	m->top_left = *top_left;
	m->bottom_right = *bottom_right;
	m->x_size = x_size;
	m->y_size = y_size;
	m->radius = radius;
	m->max_aoi_objs = max_aoi_objs;
	uint32_t x,y;
	uint32_t index = 0;
	for(y = 0; y < y_size; ++y){
		for(x = 0; x < x_size; ++x)
		{
			aoi_block *b = BLOCK(m,x,y);
			kn_dlist_init(&b->aoi_objs);
			b->x = x;
			b->y = y;
			b->index = index++; 
		}
	}	
	//计算一个视距最多可能覆盖多少个单元格
	uint32_t radius_blocksize = radius%_length == 0? radius/_length : radius/_length+1;
	radius_blocksize *= 2;
	radius_blocksize += 1;
	radius_blocksize *= radius_blocksize;
	m->new_block_set = new_bitset(x_size*y_size);
	m->old_block_set = new_bitset(x_size*y_size);
	m->new_blocks = calloc(1,sizeof(aoi_block*)*(radius_blocksize+1));
	m->old_blocks = calloc(1,sizeof(aoi_block*)*(radius_blocksize+1));
	m->enter_blocks = calloc(1,sizeof(aoi_block*)*(radius_blocksize+1));
	m->unchange_blocks = calloc(1,sizeof(aoi_block*)*(radius_blocksize+1));
	m->leave_blocks = calloc(1,sizeof(aoi_block*)*(radius_blocksize+1));
	m->_idmgr = new_idmgr(0,max_aoi_objs-1);
	return m;
}

static inline aoi_block *get_block_by_point(aoi_map *m,point2D *pos)
{	
	uint32_t x = pos->x - m->top_left.x;
	uint32_t y = pos->y - m->top_left.y;
	x = x/m->radius;
	y = y/m->radius;
	if(x > m->x_size || y > m->y_size)
		return NULL;
	return BLOCK(m,x,y);
}

static inline aoi_block **cal_blocks(aoi_map *m,aoi_block **blocks,
								     bit_set_t block_set,point2D *pos,uint32_t radius)
{
	if(get_block_by_point(m,pos) == NULL)
		return NULL;

	uint8_t c = 0;

	point2D top_left,bottom_right;
	top_left.x = pos->x - radius;
	top_left.y = pos->y - radius;
	bottom_right.x = pos->x + radius;
	bottom_right.y = pos->y + radius;
	
	if(top_left.x < m->top_left.x) top_left.x = m->top_left.x;
	if(top_left.y < m->top_left.y) top_left.y = m->top_left.y;
	if(bottom_right.x >= m->bottom_right.x) bottom_right.x = m->bottom_right.x-1;
	if(bottom_right.y >= m->bottom_right.y) bottom_right.y = m->bottom_right.y-1;
	
	aoi_block *_top_left = get_block_by_point(m,&top_left);
	aoi_block *_bottom_right = get_block_by_point(m,&bottom_right);
	uint32_t y = _top_left->y;
	for(; y <= _bottom_right->y; ++y){
		uint32_t x = _top_left->x;
		for(;x <= _bottom_right->x;++x){
			aoi_block *block = BLOCK(m,x,y);
			if(block_set) set_bit(block_set,block->index);
			blocks[c++] = block;	
		}			
	}
	blocks[c] = NULL;
	return blocks;
}

#define NEW_BLOCKS(M,POS,RADIUS) cal_blocks(M,M->new_blocks,M->new_block_set,POS,RADIUS)
#define OLD_BLOCKS(M,POS,RADIUS) cal_blocks(M,M->old_blocks,M->old_block_set,POS,RADIUS)

//计算新进入，离开，没变化的block集合
static int8_t cal_blockset(aoi_map *m,point2D *newpos,point2D *oldpos,uint32_t radius)
{
	aoi_block **new_blocks = NEW_BLOCKS(m,newpos,radius);		
	aoi_block **old_blocks = OLD_BLOCKS(m,oldpos,radius);
	if(new_blocks && old_blocks)
	{
		uint32_t i = 0;
		uint32_t c1 = 0;
		uint32_t c2 = 0;
		uint32_t c3 = 0;
		for(; old_blocks[i] ;++i){
			if(is_set(m->new_block_set,old_blocks[i]->index))
				m->unchange_blocks[c1++] = old_blocks[i];//新老集合中都存在
			else
				m->leave_blocks[c2++] = old_blocks[i];//新集合中不存在	
		}
		m->unchange_blocks[c1] = NULL;
		m->leave_blocks[c2] = NULL;
		
		for(i = 0; new_blocks[i] ;++i){
			if(is_set(m->old_block_set,new_blocks[i]->index) == 0)
				m->enter_blocks[c3++] = new_blocks[i];//老集合中不存在
		}
		m->enter_blocks[c3] = NULL;
		
		//清理new_block_set,old_block_set
		for(i = 0; new_blocks[i];++i)
			clear_bit(m->new_block_set,new_blocks[i]->index);
		for(i = 0; old_blocks[i];++i)
			clear_bit(m->old_block_set,old_blocks[i]->index);
		return 0;
	}
	return -1;
}

static inline void enter_me(aoi_object *me,aoi_object *other)
{
	set_bit(me->view_objs,other->id);
	me->cb_enter(me,other);
}

static inline void leave_me(aoi_object *me,aoi_object *other)
{
	clear_bit(me->view_objs,other->id);
	me->cb_leave(me,other);
}

static inline void block_process_enter(aoi_map *m,aoi_block *bl,aoi_object *o)
{
	aoi_object *cur = (aoi_object*)kn_dlist_begin(&bl->aoi_objs);
	aoi_object *end = (aoi_object*)kn_dlist_end(&bl->aoi_objs);
	while(cur != end){
		if(!is_set(o->view_objs,cur->id) && o->in_myscope(o,cur))enter_me(o,cur);
		if(!is_set(cur->view_objs,o->id) && cur->in_myscope(cur,o))enter_me(cur,o);
		cur = (aoi_object *)cur->node.next;
	}
}

static inline void block_process_unchange(aoi_map *m,aoi_block *bl,aoi_object *o)
{
	aoi_object *cur = (aoi_object*)kn_dlist_begin(&bl->aoi_objs);
	aoi_object *end = (aoi_object*)kn_dlist_end(&bl->aoi_objs);
	while(cur != end){	
		if(o != cur){
			if(o->in_myscope(o,cur)){
				if(!is_set(o->view_objs,cur->id))
					enter_me(o,cur);
			}else{
				if(is_set(o->view_objs,cur->id))
					leave_me(o,cur);
			}
			if(cur->in_myscope(cur,o)){
				if(!is_set(cur->view_objs,o->id))
					enter_me(cur,o);
			}else{
				if(is_set(cur->view_objs,o->id))
					leave_me(cur,o);
			}
		}		
		cur = (aoi_object *)cur->node.next;
	}
}

static inline void block_process_leave(aoi_map *m,aoi_block *bl,aoi_object *o)
{
	aoi_object *cur = (aoi_object*)kn_dlist_begin(&bl->aoi_objs);
	aoi_object *end = (aoi_object*)kn_dlist_end(&bl->aoi_objs);
	while(cur != end){
		if(is_set(o->view_objs,cur->id) && o->in_myscope(o,cur))leave_me(o,cur);
		if(is_set(cur->view_objs,o->id) && cur->in_myscope(cur,o))leave_me(cur,o);
		cur = (aoi_object *)cur->node.next;
	};
}

int32_t aoi_moveto(aoi_object *o,int32_t _x,int32_t _y)
{
	aoi_map *m = o->map;
	if(!m) return -1;	
	point2D new_pos = {_x,_y};
	point2D old_pos = o->pos;
	if(0 != cal_blockset(m,&new_pos,&old_pos,m->radius)) return -1;
	
	o->pos = new_pos;
	aoi_block *old_block = get_block_by_point(m,&old_pos);
	aoi_block *new_block = get_block_by_point(m,&new_pos);
	if(old_block != new_block)
		kn_dlist_remove(&o->node);

	uint32_t i;
	for(i = 0; m->enter_blocks[i];++i)
		block_process_enter(m,m->enter_blocks[i],o);
	
	for(i = 0; m->unchange_blocks[i];++i)
		block_process_unchange(m,m->unchange_blocks[i],o);
	
	for(i = 0; m->leave_blocks[i];++i)
		block_process_leave(m,m->leave_blocks[i],o);
		
	if(old_block != new_block)
		kn_dlist_push(&new_block->aoi_objs,&o->node);
	return 0;
}

#define ENTER_BLOCKS(M,POS,RADIUS) cal_blocks(M,M->new_blocks,NULL,POS,RADIUS)
#define LEAVE_BLOCKS(M,POS,RADIUS) cal_blocks(M,M->old_blocks,NULL,POS,RADIUS)

int32_t aoi_enter(aoi_map *m,aoi_object *o,int32_t _x,int32_t _y)
{
	o->pos.x = _x;
	o->pos.y = _y;
	aoi_block *block = get_block_by_point(m,&o->pos);
	if(!block) return -1;
	o->id = get_id(m->_idmgr);
	if(o->id == -1) return -1;
	aoi_block **blocks = ENTER_BLOCKS(m,&o->pos,m->radius);
	uint32_t i;
	for(i = 0; blocks[i];++i) block_process_enter(m,blocks[i],o);
	kn_dlist_push(&block->aoi_objs,&o->node);
	enter_me(o,o);
	o->map = m;
	return 0;
}

int32_t aoi_leave(aoi_object *o)
{
	aoi_map *m = o->map;
	if(!m) return -1;
	aoi_block *block = get_block_by_point(m,&o->pos);
	if(!block) return -1;
	kn_dlist_remove(&o->node);
	
	aoi_block **blocks = LEAVE_BLOCKS(m,&o->pos,m->radius);
	uint32_t i;
	for(i = 0; blocks[i];++i) 
		block_process_leave(m,blocks[i],o);
	//自己离开自己的视野
	leave_me(o,o);
	release_id(m->_idmgr,o->id);
	o->map = NULL;
	return 0;			
}

void  aoi_destroy(aoi_map *m)
{
	free(m->new_blocks);
	free(m->old_blocks);
	free(m->enter_blocks);
	free(m->unchange_blocks);
	free(m->leave_blocks);
	del_bitset(m->new_block_set);
	del_bitset(m->old_block_set);
	destroy_idmgr(m->_idmgr);
	free(m);
}
