#include <stdio.h>
#include <string.h>
#include "lua_util.h"
#include "astar.h"

int readline(FILE * f, char *vptr,char sep, unsigned int maxlen){
	if(f == stdin){
		int c = 0;
		for(; c < maxlen; ++c)
		{
			vptr[c] = (char)getchar();
			if(vptr[c] == sep){
				vptr[c] = '\0';
				return c+1;
			}
		}
		vptr[maxlen-1] = '\0';
		return maxlen;
	}
	else{
		long curpos = ftell(f);
		int rc = fread(vptr,1,maxlen,f);
		if(rc > 0){
			int c = 0;
			for( ; c < rc; ++c){
				if(vptr[c] == sep && (unsigned int)c < maxlen-1){
					vptr[c] = '\0';
					fseek(f,curpos+c+1,SEEK_SET);
					return c+1;
				}
			}
			if((unsigned int)c < maxlen-1)
				vptr[c] = '\0';
			else
				vptr[maxlen-1] = '\0';
			return c;
		} 
		return 0;
	}
}

static int lua_create_astar(lua_State *L){
	const char *colifile = lua_tostring(L,1);
	FILE *f = fopen(colifile,"r");
	if(!f){ 
		lua_pushnil(L);
		return 1;
	}
	else{
		
		char buf[1024];
		if(!readline(f,buf,',',1024)){
				fclose(f);
				lua_pushnil(L);
				return 1;
		}
		int xcount = atol(buf);
		if(!readline(f,buf,',',1024)){
				fclose(f);
				lua_pushnil(L);
				return 1;
		}
		int ycount = atol(buf);
		int size = xcount*ycount;
		int *coli = calloc(xcount*ycount,sizeof(int));
		int i = 0;
		for(; i < size; ++i){
			if(readline(f,buf,',',1024) == 0){
				free(coli);
				fclose(f);
				lua_pushnil(L);
				return 1;
			}
			coli[i] = atol(buf);
			if(coli[i]) coli[i] = 0xFFFFFFFF;
		}				
		AStar_t astar = create_AStar(xcount,ycount,coli);
		lua_pushlightuserdata(L,astar);
		lua_pushinteger(L,xcount);
		lua_pushinteger(L,ycount);
		free(coli);
		fclose(f);
		return 3;	
	}
}

static int lua_findpath(lua_State *L){
	AStar_t astar = lua_touserdata(L,1);
	int x1 = lua_tonumber(L,2);
	int y1 = lua_tonumber(L,3);
	int x2 = lua_tonumber(L,4);
	int y2 = lua_tonumber(L,5);
	kn_dlist path;kn_dlist_init(&path);
	if(find_path(astar,x1,y1,x2,y2,&path)){
		int i = 1;
		lua_newtable(L);
		AStarNode *n;
		while((n = (AStarNode*)kn_dlist_pop(&path))){
			lua_newtable(L);
			lua_pushinteger(L,n->x);
			lua_rawseti(L,-2,1);
			lua_pushinteger(L,n->y);
			lua_rawseti(L,-2,2);
			lua_rawseti(L,-2,i++);	
		}
	}else
		lua_pushnil(L);
	return 1;
}

int luaopen_astar(lua_State *L) {
    luaL_Reg l[] = {
        {"findpath", lua_findpath},
        {"create", lua_create_astar},
        {NULL, NULL}
    };
    luaL_newlib(L, l);
    return 1;
}
