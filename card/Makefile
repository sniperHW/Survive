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

gameserverd:\
	card/gameserver/config.c\
	card/gameserver/astar.c\
	card/gameserver/aoi.c\
	card/common/wordfilter.c\
	card/gameserver/gameserver.c\
	kendynet.a
	$(CC) $(CFLAGS) -o gameserverd $^ libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua -ldl -lm
	mv gameserverd card/gameserver
	
buildscript:
	cp card/commonscript/dbmgr.lua card/gameserver/script
	cp card/commonscript/queue.lua card/gameserver/script
	cp card/commonscript/rpc.lua card/gameserver/script
	
cleanscript:
	rm card/gameserver/script/dbmgr.lua  card/gameserver/script/queue.lua card/gameserver/script/rpc.lua
