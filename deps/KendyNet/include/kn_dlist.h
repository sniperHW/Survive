/*
    Copyright (C) <2014>  <huangweilook@21cn.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//双向链表
#ifndef _KN_DLIST_H
#define _KN_DLIST_H

struct kn_dlist;

typedef struct kn_dlist_node
{
    struct kn_dlist_node *pre;
    struct kn_dlist_node *next;
    struct kn_dlist      *owner;
}kn_dlist_node;

typedef struct kn_dlist
{
    struct kn_dlist_node head;
    struct kn_dlist_node tail;
}kn_dlist;


static inline int32_t kn_dlist_empty(kn_dlist *dl)
{
    return dl->head.next == &dl->tail ? 1:0;
}


static inline kn_dlist_node *kn_dlist_begin(kn_dlist *dl)
{
	return dl->head.next;
}

static inline kn_dlist_node *kn_dlist_end(kn_dlist *dl)
{
	return &dl->tail;
}


static inline int32_t kn_dlist_remove(kn_dlist_node *dln)
{
	if(!dln->owner || (!dln->pre && !dln->next)) return -1;
    dln->pre->next = dln->next;
	dln->next->pre = dln->pre;
	dln->pre = dln->next = NULL;
	dln->owner = NULL;
	return 0;
}

static inline kn_dlist_node *kn_dlist_pop(kn_dlist *dl)
{
	kn_dlist_node *n = NULL;
    if(!kn_dlist_empty(dl)){
        n = dl->head.next;
        kn_dlist_remove(n);
	}
	return n;
}

static inline int32_t kn_dlist_push(kn_dlist *dl,kn_dlist_node *dln)
{
	if(dln->owner || dln->pre || dln->next) return -1;
	dl->tail.pre->next = dln;
	dln->pre = dl->tail.pre;
	dl->tail.pre = dln;
	dln->next = &dl->tail;
	dln->owner = dl; 
	return 0;
}

static inline int32_t kn_dlist_push_front(kn_dlist *dl,kn_dlist_node *dln)
{
	if(dln->owner || dln->pre || dln->next) return -1;
	kn_dlist_node *next = dl->head.next;
	dl->head.next = dln;
	dln->pre = &dl->head;
	dln->next = next;
	next->pre = dln;
	dln->owner = dl;
	return 0;
}

static inline void kn_dlist_init(kn_dlist *dl)
{
	dl->head.pre = dl->tail.next = NULL;
	dl->head.next = &dl->tail;
	dl->tail.pre = &dl->head;
}

//if the dblnk_check return 1,dln will be remove
typedef int8_t (*dblnk_check)(kn_dlist_node*,void *);

static inline void kn_dlist_check_remove(kn_dlist *dl,dblnk_check _check,void *ud)
{
    if(kn_dlist_empty(dl)) return;

    kn_dlist_node* dln = dl->head.next;
    while(dln != &dl->tail)
    {
        kn_dlist_node *tmp = dln;
        dln = dln->next;
        if(_check(tmp,ud) == 1){
            //remove
            kn_dlist_remove(tmp);
        }
    }
}

#endif
