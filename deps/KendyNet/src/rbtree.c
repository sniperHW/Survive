#include "rbtree.h"
#define RED 1
#define BLACK 2

rbtree_t create_rbtree(cmp_function compare_function)
{
	rbtree_t rb = malloc(sizeof(*rb));
	if(rb)
	{
		rb->size = 0;
		rb->dummy.color = BLACK;
		rb->nil = &rb->dummy;
		rb->nil->tree = rb;
		rb->root = rb->nil;
		rb->compare_function = compare_function;
	}
	return rb;
}

void destroy_rbtree(rbtree_t *rb)
{
	free(*rb);
	*rb = NULL;
}


static inline void rotate_left(rbtree_t rb,struct rbnode *n)
{
	struct rbnode *parent = n->parent;
	struct rbnode *right  = n->right;
	if(right == rb->nil)
		return;

	n->right = right->left;
	if(right->left != rb->nil)
		right->left->parent = n;

	if(n == rb->root)
		rb->root = right;
	else
	{
		if(n == parent->left)
			parent->left = right;
		else
			parent->right = right;
	}
	if(right != rb->nil)
		right->parent = parent;
	n->parent = right;
	right->left = n;
}


static  inline void rotate_right(rbtree_t rb,struct rbnode *n)
{
	struct rbnode *parent = n->parent;
	struct rbnode *left  = n->left;
	if(left == rb->nil)
		return;
	n->left = left->right;
	if(left->right != rb->nil)
		left->right->parent = n;

	if(n == rb->root)
		rb->root = left;
	else
	{
		if(n == parent->left)
			parent->left = left;
		else
			parent->right = left;
	}
	if(left != rb->nil)
		left->parent = parent;
	n->parent = left;
	left->right = n;
}

inline static void color_flip(struct rbnode *n)
{
	if(n->left && n->right)
	{
		n->color = RED;
		n->left->color = n->right->color = BLACK;
	}
}

static void insert_fix_up(rbtree_t rb,struct rbnode *n)
{
	while(n->parent->color == RED)
	{
		struct rbnode *parent = n->parent;
		struct rbnode *grand_parent = parent->parent;
		if(parent == grand_parent->left)
		{
			struct rbnode *ancle = grand_parent->right;
			if(ancle->color == RED)
			{
				color_flip(grand_parent);
				n = grand_parent;
			}
			else
			{
				if(n == parent->right)
				{
					n = parent;
					rotate_left(rb,n);
				}

				n->parent->color = BLACK;
				n->parent->parent->color = RED;
				rotate_right(rb,n->parent->parent);
			}
		}
		else
		{
			struct rbnode *ancle = grand_parent->left;
			if(ancle->color == RED)
			{
				color_flip(grand_parent);
				n = grand_parent;
			}
			else
			{
				if(n == parent->left)
				{
					n = parent;
					rotate_right(rb,n);
				}
				n->parent->color = BLACK;
				n->parent->parent->color = RED;
				rotate_left(rb,n->parent->parent);
			}
		}
	}
	rb->root->color = BLACK;
}


int8_t rbtree_insert(rbtree_t rb,struct rbnode *n)
{
	assert(rb);
    struct rbnode *cur = rb->root;
    struct rbnode *parent = rb->nil;
    struct rbnode **child_link = NULL;
	while(cur != rb->nil)
	{
        parent = cur;
		
		char ret = rb->compare_function(n->key,cur->key);
		if(ret == 0) return -1;
		else if(ret == -1)
		{
            child_link = &cur->left;
			cur = cur->left;
		}
		else
		{
		    child_link = &cur->right;
			cur = cur->right;
		}
	}

    n->color = RED;
	n->left = n->right = rb->nil;
    n->parent = parent;
    n->tree = rb;
    if(child_link)
        *child_link = n;
	if(++rb->size == 1)
        rb->root = n;
	insert_fix_up(rb,n);
	return 0;
}



static inline struct rbnode *get_delete_node(rbtree_t rb,struct rbnode *n)
{
	if(n->left == rb->nil && n->right == rb->nil)
		return n;
	else if(n->right != rb->nil)
		return minimum(rb,n->right);
	else
		return maxmum(rb,n->left);
}

static void delete_fix_up(rbtree_t rb,struct rbnode *n)
{
	while(n != rb->root && n->color != RED)
	{
		struct rbnode *p = n->parent;
		if(n == p->left)
		{
			struct rbnode *w = p->right;
			if(w->color == RED)
			{
				w->color = BLACK;
				p->color = RED;
				rotate_left(rb,p);
				w = p->right;
			}
			if(w->left->color == BLACK && w->right->color == BLACK)
			{
				w->color = RED;
				n = p;
			}
			else
			{
				if(w->right->color == BLACK)
				{
					w->left->color = BLACK;
					w->color = RED;
					rotate_right(rb,w);
					w = p->right;
				}
				w->color = p->color;
				p->color = BLACK;
				w->right->color = BLACK;
				rotate_left(rb,p);
				n = rb->root;
			}
		}
		else
		{
			struct rbnode *w = p->left;
			if(w->color == RED)
			{
				w->color = BLACK;
				p->color = RED;
				rotate_right(rb,p);
				w = p->left;
			}
			if(w->left->color == BLACK && w->right->color == BLACK)
			{
				w->color = RED;
				n = p;
			}
			else
			{
				if(w->left->color == BLACK)
				{
					w->right->color = BLACK;
					w->color = RED;
					rotate_left(rb,w);
					w = p->left;
				}
				w->color = p->color;
				p->color = BLACK;
				w->left->color = BLACK;
				rotate_right(rb,p);
				n = rb->root;
			}
		}
	}
	n->color = BLACK;
}

static inline int8_t rb_delete(rbtree_t rb,struct rbnode *n)
{
	struct rbnode *x = get_delete_node(rb,n);
	if(!x)
		return -1;
	struct rbnode *parent = x->parent;
	struct rbnode **link = (x == parent->left)? &(parent->left):&(parent->right);
	struct rbnode *z;
	if(x->left != rb->nil)
        *link = x->left;
    else if(x->right != rb->nil)
        *link = x->right;
    else
        *link = rb->nil;
	if((z = *link) != rb->nil)
        z->parent = parent;
    x->parent = x->left = x->right = rb->nil;
	uint8_t x_old_color = x->color;
	if(n != x)
	{
		struct rbnode *n_left = n->left;
		struct rbnode *n_right = n->right;
		struct rbnode *n_parent = n->parent;
		if(n_left != rb->nil)
		{
			n_left->parent = x;
			x->left = n_left;
		}
		if(n_right != rb->nil)
		{
			n_right->parent = x;
			x->right = n_right;
		}
		if(n_parent != rb->nil)
		{
			if(n == n_parent->left)
				n_parent->left = x;
			else
				n_parent->right = x;
			x->parent = n_parent;
		}
		x->color = n->color;
        if(n == rb->root)
            rb->root = x;//if n is the old root,now the new root is x
	}
	if(--rb->size == 0)
        rb->root = rb->nil;
    else if(z != rb->nil && x_old_color == BLACK)
            delete_fix_up(rb,z);
	return 0;
}

int8_t rbtree_erase(struct rbnode *n)
{
	if(!n->tree)
		return -1;
	return rb_delete(n->tree,n);
}

struct rbnode* rbtree_remove(rbtree_t rb,void *key)
{
	struct rbnode *n = rbtree_find(rb,key);
	if(n)
	{
		rbtree_erase(n);
		return n;
	}
	return NULL;
}


/*
int32_t check(rbtree_t rb,struct rbnode *n,int32_t level,int32_t black_level,int32_t *max_black_level,int32_t *max_level)
{
	if(n == rb->nil)
		return 1;
	if(n->color == BLACK)
		++black_level;
	else
	{
		if(n->parent->color == RED)
		{
			printf("040809¨¨0002040201¨¦0408¨¨0905010002RED\n");
			return 0;
		}
	}
	++level;
	if(n->left == rb->nil && n->right == rb->nil)
	{
		//0208¡ã¨¨0606020509¨¨0002040201
		if(level > *max_level)
			*max_level = level;
		if(*max_black_level == 0)
			*max_black_level = black_level;
		else
			if(*max_black_level != black_level)
			{
				printf("¨¦0307¨¨0905¨¨00020402010301¡ã040703010003010000¨¨0707\n");
				return 0;
			}
		return 1;
	}
	else
	{
		if(0 == check(rb,n->left,level,black_level,max_black_level,max_level))
			return 0;
		if(0 == check(rb,n->right,level,black_level,max_black_level,max_level))
			return 0;
	}
	return 1;
}

void rbtree_check_vaild(rbtree_t rb)
{
	assert(rb);
	if(rb->root != rb->nil)
	{
		int32_t max_black_level = 0;
		int32_t max_level = 0;
		if(check(rb,rb->root,0,0,&max_black_level,&max_level))
			printf("max_black_level:%d,max_level:%d\n",max_black_level,max_level);
	}
}*/
