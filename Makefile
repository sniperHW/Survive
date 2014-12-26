CFLAGS = -g -Wall -fno-strict-aliasing -std=gnu99
SHARED = -fPIC -shared
CC = gcc
DEFINE = -D_DEBUG -D_LINUX 
INCLUDE = -I../KendyNet/include -I../deps -I../deps/lua-5.2.3/src
	
all:
	$(CC) $(CFLAGS) $(SHARED) -o aoi.so common/aoi.c common/lua_aoi.c ../KendyNet/libkendynet.a $(INCLUDE) $(DEFINE)
	$(CC) $(CFLAGS) $(SHARED) -o astar.so common/astar.c common/lua_astar.c ../KendyNet/libkendynet.a $(INCLUDE) $(DEFINE)	