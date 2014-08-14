CFLAGS = -g -Wall -fno-strict-aliasing -std=gnu99 -rdynamic
LDFLAGS = -lpthread -lrt -lm -ltcmalloc -llua5.2
SHARED = -fPIC --shared
CC = gcc
INCLUDE =  -I../KendyNet/include -I./Survive -I./deps -I/usr/include/lua5.2

kendynet.a: \
		   ../KendyNet/src/kn_epoll.c \
		   ../KendyNet/src/kn_timerfd.c \
		   ../KendyNet/src/kn_timer.c \
		   ../KendyNet/src/kn_time.c \
		   ../KendyNet/src/redisconn.c\
		   ../KendyNet/src/kn_chr_dev.c\
		   ../KendyNet/src/kn_refobj.c \
		   ../KendyNet/src/rpacket.c \
		   ../KendyNet/src/wpacket.c \
		   ../KendyNet/src/packet.c \
		   ../KendyNet/src/kn_socket.c \
		   ../KendyNet/src/kn_refobj.c \
		   ../KendyNet/src/stream_conn.c \
		   ../KendyNet/src/kn_thread.c \
		   ../KendyNet/src/kn_thread_mailbox.c \
		   ../KendyNet/src/hash_map.c \
		   ../KendyNet/src/kn_except.c \
		   ../KendyNet/src/lookup8.c \
		   ../KendyNet/src/spinlock.c \
		   ../KendyNet/src/log.c \
		   ../KendyNet/src/kn_string.c \
		   ../KendyNet/src/minheap.c \
		   ../KendyNet/src/buffer.c
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
	$(CC) $(CFLAGS) -o gateserverd $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua5.2 -ldl -lm
	mv gateserverd Survive/gateserver

groupserverd:\
	Survive/common/netcmd.h\
	Survive/common/common_c_function.h\
	Survive/groupserver/groupserver.c\
	Survive/groupserver/config.c\
	Survive/common/wordfilter.c\
	kendynet.a
	$(CC) $(CFLAGS) -o groupserverd $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua5.2 -ldl -lm
	mv groupserverd Survive/groupserver

gameserverd:\
	Survive/gameserver/config.c\
	Survive/gameserver/astar.c\
	Survive/gameserver/aoi.c\
	Survive/common/wordfilter.c\
	Survive/gameserver/gameserver.c\
	kendynet.a
	$(CC) $(CFLAGS) -o gameserverd $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -llua5.2 -ldl -lm
	mv gameserverd Survive/gameserver
	
testclient:\
	testclient.c\
	kendynet.a
	$(CC) $(CFLAGS) -o testclient $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -ldl -lm
	
testpacket:\
	testpacket.c\
	kendynet.a
	$(CC) $(CFLAGS) -o testpacket $^ ./deps/hiredis/libhiredis.a $(INCLUDE) $(LDFLAGS) $(DEFINE) -ldl -lm
	
testtop:\
	testtop.c \
	./deps/top/libproc.a
	$(CC) $(CFLAGS) -o testtop $^ ./deps/top/libproc.a -Ideps/top $(LDFLAGS) $(DEFINE) -ldl -lm	

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
