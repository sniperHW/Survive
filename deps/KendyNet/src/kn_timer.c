#include "kendynet_private.h"
#include "kn_timer.h"
#include "kn_timer_private.h"
#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "kn_time.h"
#include "kn_dlist.h"

typedef struct kn_timer{
	kn_dlist_node node;             //同一时间过期的timer被连接在一起
	uint64_t      timeout;
	uint64_t      expire;
	void          *ud;
	kn_cb_timer   timeout_callback;
	kn_timermgr_t mgr;
}*kn_timer_t;


struct timing_wheel{
	uint8_t  type;
	uint16_t curslot;
	uint16_t slotsize;
	kn_dlist wheel[0]; 
};


enum{
	wheel_ms,   //1000
	wheel_sec,  //60
	wheel_min,  //60
	wheel_hour, //24
	wheel_day, //60 定时器最大计量60天内的时间
	wheel_max,
};

struct timing_wheel* new_timing_wheel(uint8_t type){
	struct timing_wheel *wheel;
	if(type == wheel_ms){
		wheel = calloc(1,sizeof(*wheel)*1000*sizeof(kn_dlist));
		wheel->slotsize = 1000;
	}else if(type == wheel_sec || type == wheel_min || type == wheel_day){
		wheel = calloc(1,sizeof(*wheel)*60*sizeof(kn_dlist));
		wheel->slotsize = 60;
	}else if(type == wheel_hour){
		wheel = calloc(1,sizeof(*wheel)*24*sizeof(kn_dlist));
		wheel->slotsize = 24;	
	}else 
		return NULL;

	wheel->curslot = 1;
	wheel->type = type;
	uint16_t i = 0;
	for(; i < wheel->slotsize; ++i){
		kn_dlist_init(&wheel->wheel[i]);
	}
	return wheel;	
}

typedef struct kn_timermgr{
	struct timing_wheel *wheels[wheel_max];
	kn_dlist      pending_reg;
	uint64_t      last_tick;
	uint8_t       intick;
}*kn_timermgr_t;

static inline void _reg_timer(kn_timer_t timer,uint8_t setexpire){
	if(setexpire && timer->mgr->intick){
		kn_dlist_push(&timer->mgr->pending_reg,(kn_dlist_node*)timer);	
		return;
	}
	struct timing_wheel *wheel = NULL;
	uint64_t duration = timer->timeout;
	uint64_t now = kn_systemms64();
	if(setexpire)
		timer->expire = timer->timeout + kn_systemms64();
	else
		duration = timer->expire > now ?timer->expire - now:0;
	do{
		//选择一个合适的wheel插入
		wheel = timer->mgr->wheels[wheel_ms];
		uint64_t t = wheel->slotsize - wheel->curslot;
		if(t >= duration) break;
		duration /= 1000;
		wheel = timer->mgr->wheels[wheel_sec];
		t = wheel->slotsize - wheel->curslot;
		if(t >= duration) break;
		duration /= 60;
		wheel = timer->mgr->wheels[wheel_min];
		t = wheel->slotsize - wheel->curslot;
		if(t >= duration) break;
		duration /= 60;
		wheel = timer->mgr->wheels[wheel_hour];
		t = wheel->slotsize - wheel->curslot;
		if(t >= duration) break;
		wheel = timer->mgr->wheels[wheel_day];
		duration /= 24;
		if(duration > wheel->slotsize) wheel = NULL;								
	}while(0);
	assert(wheel);
	if(duration >= 1) duration -= 1;
	uint16_t index = (wheel->curslot + duration)%wheel->slotsize;
	//printf("c:%d,i:%d,t:%d,d:%d\n",wheel->curslot,index,wheel->type,duration);
	kn_dlist_push(&wheel->wheel[index],(kn_dlist_node*)timer);
}

static void tick_wheel(kn_timermgr_t t,struct timing_wheel *wheel){
	if(wheel->type == wheel_ms){
		kn_dlist_node *c = kn_dlist_pop(&wheel->wheel[wheel->curslot]);
		while(c){
			kn_timer_t timer = (kn_timer_t)c;
			if(timer->timeout_callback(timer))
				_reg_timer(timer,1);			
			c = kn_dlist_pop(&wheel->wheel[wheel->curslot]);
		}
	}else{
		kn_dlist_node *c = kn_dlist_pop(&wheel->wheel[wheel->curslot]);
		while(c){
			_reg_timer((kn_timer_t)c,0);
			c = kn_dlist_pop(&wheel->wheel[wheel->curslot]);
		}
	}
	wheel->curslot = (wheel->curslot+1)%wheel->slotsize;
	if(wheel->curslot == 0 && wheel->type != wheel_day)
		tick_wheel(t,t->wheels[wheel->type+1]);
}

void kn_timermgr_tick(kn_timermgr_t t){
	uint64_t now =  kn_systemms64();
	uint64_t elapse = now - t->last_tick;
	t->intick = 1;
	while(elapse > 0){
		tick_wheel(t,t->wheels[wheel_ms]);
		elapse--;
	}
	t->intick = 0;
	kn_dlist_node *c = kn_dlist_pop(&t->pending_reg);
	while(c){
		_reg_timer((kn_timer_t)c,1);
		c = kn_dlist_pop(&t->pending_reg);
	}
	t->last_tick = now;
}

static uint64_t MAX_TIMEOUT = 5184000000;//60*24*3600*1000

kn_timer_t reg_timer_imp(kn_timermgr_t t,
						 uint64_t timeout,
						 kn_cb_timer cb,
						 void *ud)
{
	if(timeout == 0 || timeout > MAX_TIMEOUT) return NULL;
	kn_timer_t timer = calloc(1,sizeof(*timer));
	timer->ud = ud;
	timer->timeout_callback = cb;
	timer->mgr = t;
	timer->timeout = timeout;
	_reg_timer(timer,1);
	return timer;
}

void  kn_del_timer(kn_timer_t timer){
	if(timer->mgr)
		kn_dlist_remove((kn_dlist_node*)timer);
	free(timer);
}

void* kn_timer_getud(kn_timer_t timer){
	return timer->ud;
}

void kn_del_timermgr(kn_timermgr_t t){
	int i = 0;
	for(; i < wheel_max; ++i){
		int j = 0;
		for(; j < t->wheels[i]->slotsize; ++j){
			kn_dlist *l = &t->wheels[i]->wheel[j];
			kn_dlist_node *c = kn_dlist_pop(l);
			while(c){
				free(c);
				c = kn_dlist_pop(l);
			}
		}
		free(t->wheels[i]);
	}
	kn_dlist_node *c = kn_dlist_pop(&t->pending_reg);
	while(c){
		free(c);
		c = kn_dlist_pop(&t->pending_reg);
	}
	free(t);
}

kn_timermgr_t kn_new_timermgr(){
	kn_timermgr_t t = calloc(1,sizeof(*t));
	int i = 0;
	for(; i < wheel_max; ++i){
		t->wheels[i] = new_timing_wheel(i);
	}
	t->last_tick = kn_systemms64();
	kn_dlist_init(&t->pending_reg);
	return t;
}
