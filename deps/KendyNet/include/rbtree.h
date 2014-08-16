/*
    Copyright (C) <2012>  <huangweilook@21cn.com>

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
#ifndef _RBTREE_H
#define _RBTREE_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

struct rbtree;

struct rbnode{
	struct rbnode *parent;
	struct rbnode *left;
	struct rbnode *right;
	void   *key;
	struct rbtree *tree;
	uint8_t color;
};

typedef int32_t (*cmp_function)(void*,void*);

typedef struct rbtree{
	struct rbnode *root;
	struct rbnode *nil;
	uint32_t size;
	cmp_function compare_function;
	struct rbnode  dummy;
}*rbtree_t;

rbtree_t create_rbtree(cmp_function);
void     destroy_rbtree(rbtree_t *);
int8_t   rbtree_insert(rbtree_t,struct rbnode*);
int8_t   rbtree_erase(struct rbnode*);
struct rbnode*  rbtree_remove(rbtree_t,void *key);
//void     rbtree_check_vaild(rbtree_t rb);


static inline uint32_t rbtree_size(rbtree_t rb)
{
	return rb->size;
}

static inline int8_t   rbtree_isempty(rbtree_t rb)
{
	return rb->size == 0 ? 1:0;
}

static inline struct rbnode *minimum(rbtree_t rb,struct rbnode *n)
{
	while(n->left != rb->nil)
		n = n->left;
	return n;
}

static inline struct rbnode *maxmum(rbtree_t rb,struct rbnode *n)
{
	while(n->right != rb->nil)
		n = n->right;
	return n;
}


static inline struct rbnode *successor(rbtree_t rb,struct rbnode *n)
{
	assert(rb);
	if(n->right != rb->nil)
		return minimum(rb,n->right);
	struct rbnode *y = n->parent;
	while(y != rb->nil && n == y->right)
	{
		n = y;
		y = y->parent;
	}
	return y;
}

static inline struct rbnode *predecessor(rbtree_t rb,struct rbnode *n)
{
	assert(rb);
	if(n->left != rb->nil)
		return maxmum(rb,n->left);
	struct rbnode *y = n->parent;
	while(y != rb->nil && n == y->left)
	{
		n = y;
		y = y->parent;
	}
	return y;
}

static inline struct rbnode*  rbtree_first(rbtree_t rb)
{
	if(rb->size == 0)
		return NULL;
	return minimum(rb,rb->root);
}

static inline struct rbnode*  rbtree_last(rbtree_t rb)
{
	if(rb->size == 0)
		return NULL;
	return maxmum(rb,rb->root);
}

static inline struct rbnode*  rbnode_next(struct rbnode *n)
{
	if(!n)
		return NULL;
	rbtree_t rb = n->tree;
	struct rbnode *succ = successor(rb,n);
	if(succ == rb->nil)
		return NULL;
	return succ;
}

static inline struct rbnode*  rbnode_pre(struct rbnode*n)
{
	if(!n)
		return NULL;
	rbtree_t rb = n->tree;
	struct rbnode *presucc = predecessor(rb,n);
	if(presucc == rb->nil)
		return NULL;
	return presucc;
}

static inline struct rbnode*  rbtree_find(rbtree_t rb,void *key)
{
    if(rb->root == rb->nil)
		return NULL;
	struct rbnode *cur = rb->root;
	while(cur != rb->nil)
	{
		char ret = rb->compare_function(key,cur->key);
		if(ret == 0) return cur;
		else if(ret == -1)cur = cur->left;
		else cur = cur->right;
	}
	return NULL;
}

#endif

