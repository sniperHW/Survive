CFLAGS = -O2 -g -Wall 
LDFLAGS = -lpthread -lrt -lm -ltcmalloc
SHARED = -fPIC --shared
CC = gcc
INCLUDE = -I../kendynet -I../kendynet/core -I.. -I. -Igateserver -Igameserver\
		  -I../kendynet/deps/luajit-2.0/src -I../kendynet/deps/hiredis
DEFINE = -D_DEBUG -D_LINUX -DMQ_HEART_BEAT

gateservice.a:\
		gateserver/agentservice/agentservice.c\
		gateserver/agentservice/agentservice.h\
		gateserver/verifyservice/verifyservice.c\
		gateserver/verifyservice/verifyservice.h\
		gateserver/togame/togame.c\
		gateserver/togame/togame.h
		$(CC) $(CFLAGS) -c $^ $(INCLUDE) $(DEFINE)
		ar -rc gateservice.a *.o
		rm -f *.o
		
gameservice.a:\
		gameserver/avatar.c\
		gameserver/avatar.h\
		gameserver/superservice/superservice.c\
		gameserver/superservice/superservice.h\
		gameserver/battleservice/battleservice.h\
		gameserver/battleservice/battleservice.c\
		gameserver/battleservice/map.c\
		gameserver/battleservice/map.h		
		$(CC) $(CFLAGS) -c $^ $(INCLUDE) $(DEFINE)
		ar -rc gameservice.a *.o
		rm -f *.o

