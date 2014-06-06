#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "wordfilter.h"


struct token{ 
	char   code;       //字符的编码     
	struct token   **children;       //子节点
	uint32_t       children_size;  //子节点的数量
    uint8_t        end;          //是否一个word的结尾
};


typedef struct wordfilter{
	struct token * tokarry[256];
}*wordfilter_t;

struct token *inserttoken(struct token *tok,char c)     
{
	struct token *child = calloc(1,sizeof(*child));
	child->code = c;
	if(tok->children_size == 0){
		tok->children = calloc(tok->children_size+1,sizeof(child));
		tok->children[0] = child;
	}else{
		struct token **tmp = calloc(tok->children_size+1,sizeof(*tmp));
		int i = 0;
		int flag = 0;
		for(; i < tok->children_size; ++i){
			if(!flag && tok->children[i]->code > c){
				tmp[i] = child;
				flag = 1;
			}else
				tmp[i] = tok->children[i];
		}
		if(!flag) 
			tmp[tok->children_size] = child;
		else
			tmp[tok->children_size] = tok->children[tok->children_size-1];
		free(tok->children);
		tok->children = tmp;
	}
	tok->children_size++;
	return child;	
}     

static struct token *getchild(struct token *tok,char c)     
{   
	
	if(!tok->children_size) return NULL;
	int left = 0;
	int right = tok->children_size - 1;
	for( ; ; )
	{
		if(right - left <= 0)
			return tok->children[left]->code == c ? tok->children[left]:NULL; 
		int index = (right - left)/2 + left;
		if(tok->children[index]->code == c)
			return tok->children[index];
		else if(tok->children[index]->code > c)
			right = index-1;
		else
			left = index+1;
	} 
}


static struct token *addchild(struct token *tok,char c){
	struct token *child = getchild(tok,c);
	if(!child)
		return inserttoken(tok,c);
	return child;
}

static void NextChar(struct token *tok,const char *str,int i,int *maxmatch)     
{ 
	if(str[i] == 0) return;      
    struct token *childtok = getchild(tok,str[i]);  
    if(childtok)     
    {     
        if(childtok->end)     
            *maxmatch = i + 1;     
        NextChar(childtok,str,i+1,maxmatch);     
    }
	else{
		if(tok->end)
			*maxmatch = i;
	}
}   


static uint8_t processWord(wordfilter_t filter,const char *str,int *pos)     
{   
	struct token *tok = filter->tokarry[(uint8_t)str[*pos]];
	if(tok == NULL)
	{
		(*pos) += 1;
		return 0;
	}else{
		int maxmatch = 0;     
        NextChar(tok,str,(*pos)+1,&maxmatch);                      
        if(maxmatch == 0)     
        {     
            (*pos) += 1;
			if(tok->end)
				return 1;
            return 0;     
        }     
        else     
        {     
            (*pos) = maxmatch;     
            return 1;     
        }   
	}
	return 0;
}

wordfilter_t wordfilter_new(const char **forbidwords){
	wordfilter_t filter = calloc(1,sizeof(*filter));
	int i = 0;
	for(;forbidwords[i] != NULL; ++i){
		const char *str = forbidwords[i];
		int size = strlen(str);
		struct token *tok = filter->tokarry[(uint8_t)str[0]];
		if(!tok){
			tok = calloc(1,sizeof(*tok));
			tok->code = str[0];
			filter->tokarry[(uint8_t)str[0]] = tok;
		} 
		int j = 1;
		for(; j < size;++j)     
			tok = addchild(tok,str[j]);
		tok->end = 1; 
	}
	return filter;
}     

uint8_t isvaildword(wordfilter_t filter,const char *str)
{
	uint8_t ret = 1;
	//首先将srt从const char *转换成_char*
	int size = strlen(str);
	int i = 0;
    for(; i < size;)     
    {       
        if(processWord(filter,str,&i)){
			ret = 0;
			break;
		}
    } 
	return ret;
}

string_t wordfiltrate(wordfilter_t filter,const char *str,char replace){
	int size = strlen(str);
	int i,j;	
	char *tmp = calloc(1,size+1);
	strcpy(tmp,str);
	for(i = 0; i < size;)     
    {     
        int o = i;     
        if(processWord(filter,str,&i)){       
			 j = o;           
			 for(; j < i; ++j) tmp[j] = replace;
		}
    }
    
    string_t ret = new_string(tmp);
    //将连续的replace符号合成1个
    int flag = 0;
    j = 0;
    for(i = 0; i < size; ++i){
		if(tmp[i] == replace){
			if(!flag){
				flag = 1;
				++j;
			}
		}else{
			((char*)to_cstr(ret))[j++] = tmp[i];
			if(flag) flag = 0;
		}
	}
	free(tmp);
	((char*)to_cstr(ret))[j] = 0; 
    return ret;
       
}  
