CFLAGS = -g -Wall -fno-strict-aliasing -std=gnu99 -rdynamic
LDFLAGS = -lpthread -lrt -lm
SHARED = -fPIC --shared
CC = gcc
INCLUDE = -Ideps/KendyNet/include -Ideps -Ideps/lua-5.2.3/src -I./Survive
LIB = -L deps/jemalloc/lib -L deps/KendyNet -L deps/hiredis/ -L deps/http-parser -L deps/lua-5.2.3/src

deps/KendyNet/libkendynet.a:
		cd deps/KendyNet;make libkendynet.a
deps/jemalloc/lib/libjemalloc.a:
		cd deps/jemalloc;./configure;make
deps/hiredis/libhiredis.a:
		cd deps/hiredis/;make
		
deps/lua-5.2.3/src/liblua.a:		
		cd deps/lua-5.2.3/;make linux					
cjson.so:
		cd deps/lua-cjson-2.1.0;make
		mv deps/lua-cjson-2.1.0/cjson.so ./

gateserverd:deps/KendyNet/libkendynet.a\
    deps/jemalloc/lib/libjemalloc.a\
    deps/hiredis/libhiredis.a\
	deps/lua-5.2.3/src/liblua.a\
	Survive/common/netcmd.h\
	Survive/gateserver/agent.c\
	Survive/gateserver/gateserver.c\
	Survive/gateserver/toinner.c
	$(CC) $(CFLAGS) -o gateserverd $^ -lkendynet -lhiredis -ljemalloc -llua $(INCLUDE) $(LDFLAGS) $(DEFINE) $(LIB)
	mv gateserverd Survive/gateserver
	
testclient:\
	testclient.c\
	kendynet.a
	$(CC) $(CFLAGS) -o testclient $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -ldl -lm
