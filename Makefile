CFLAGS = -g -Wall -fno-strict-aliasing -std=gnu99 -rdynamic
LDFLAGS = -lpthread -lrt -lm -ltcmalloc
SHARED = -fPIC --shared
CC = gcc
INCLUDE =  -I../KendyNet/include -I./Survive -I../KendyNet

kendynet.a: \
		   ../KendyNet/src/kn_connector.c \
		   ../KendyNet/src/kn_epoll.c \
		   ../KendyNet/src/kn_except.c \
		   ../KendyNet/src/kn_proactor.c \
		   ../KendyNet/src/kn_ref.c \
		   ../KendyNet/src/kn_acceptor.c \
		   ../KendyNet/src/kn_fd.c \
		   ../KendyNet/src/kn_datasocket.c \
		   ../KendyNet/src/kendynet.c \
		   ../KendyNet/src/kn_time.c \
		   ../KendyNet/src/kn_thread.c\
		   ../KendyNet/src/buffer.c\
		   ../KendyNet/src/kn_string.c\
		   ../KendyNet/src/wpacket.c\
		   ../KendyNet/src/rpacket.c\
		   ../KendyNet/src/kn_timer.c\
		   ../KendyNet/src/kn_stream_conn.c\
		   ../KendyNet/src/kn_stream_conn_server.c\
		   ../KendyNet/src/kn_stream_conn_client.c\
		   ../KendyNet/src/minheap.c\
		   ../KendyNet/src/hash_map.c\
		   ../KendyNet/src/rbtree.c\
		   ../KendyNet/src/spinlock.c\
		   ../KendyNet/src/obj_allocator.c\
		   ../KendyNet/src/log.c\
		   ../KendyNet/src/redisconn.c\
		   ../KendyNet/src/tls.c\
		   ../KendyNet/src/lua_util.c\
		   ../KendyNet/src/kn_timerfd.c\
		   ../KendyNet/src/kn_channel.c
		$(CC) $(CFLAGS) -c $^ $(INCLUDE) $(DEFINE)
		ar -rc kendynet.a *.o
		rm -f *.o

gateserverd:\
	Survive/common/netcmd.h\
	Survive/gateserver/agent.c\
	Survive/gateserver/gateserver.c\
	Survive/gateserver/config.c\
	Survive/gateserver/togrpgame.c\
	kendynet.a
	$(CC) $(CFLAGS) -o gateserverd $^ libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua -ldl -lm
	mv gateserverd Survive/gateserver


groupserverd:\
	Survive/common/netcmd.h\
	Survive/common/common_c_function.h\
	Survive/groupserver/groupserver.c\
	Survive/groupserver/config.c\
	Survive/common/wordfilter.c\
	kendynet.a
	$(CC) $(CFLAGS) -o groupserverd $^ libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua -ldl -lm
	mv groupserverd Survive/groupserver

gameserverd:\
	Survive/gameserver/config.c\
	Survive/gameserver/astar.c\
	Survive/gameserver/aoi.c\
	Survive/common/wordfilter.c\
	Survive/gameserver/gameserver.c\
	kendynet.a
	$(CC) $(CFLAGS) -o gameserverd $^ libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua -ldl -lm
	mv gameserverd Survive/gameserver
	
testclient:\
	testclient.c\
	kendynet.a
	$(CC) $(CFLAGS) -o testclient $^ libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua -ldl -lm
	
buildscript:
	cp Survive/commonscript/dbmgr.lua Survive/groupserver/script
	cp Survive/commonscript/queue.lua Survive/groupserver/script
	cp Survive/commonscript/rpc.lua Survive/groupserver/script
	cp Survive/commonscript/dbmgr.lua Survive/gameserver/script
	cp Survive/commonscript/queue.lua Survive/gameserver/script
	cp Survive/commonscript/rpc.lua Survive/gameserver/script
	
cleanscript:
	rm Survive/gameserver/script/dbmgr.lua  Survive/gameserver/script/queue.lua Survive/gameserver/script/rpc.lua
	rm Survive/groupserver/script/dbmgr.lua Survive/groupserver/script/queue.lua Survive/groupserver/script/rpc.lua	
