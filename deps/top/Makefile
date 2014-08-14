CFLAGS = -g
LDFLAGS = -lpthread -lrt -lm -ldl -ltcmalloc 
SHARED = -fPIC -shared
CC = gcc
INCLUDE = -I proc

all:
	cc -D_GNU_SOURCE $(INCLUDE) -MM -MG proc/alloc.c proc/devname.c proc/escape.c proc/ksym.c proc/pwcache.c proc/readproc.c proc/sig.c proc/slab.c proc/sysinfo.c proc/version.c proc/whattime.c > proc/.depend
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/alloc.c -o proc/alloc.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/devname.c -o proc/devname.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/escape.c -o proc/escape.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/ksym.c -o proc/ksym.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/pwcache.c -o proc/pwcache.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/readproc.c -o proc/readproc.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/sig.c -o proc/sig.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/slab.c -o proc/slab.o
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/sysinfo.c -o proc/sysinfo.o
	cc -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) -DVERSION=\"3\" -DSUBVERSION=\"2\" -DMINORVERSION=\"8\" -c -o proc/version.o proc/version.c
	cc -D_GNU_SOURCE $(INCLUDE) $(CFLAGS) -c -o top.o top.c	
	cc -c -D_GNU_SOURCE $(INCLUDE)  $(CFLAGS) proc/whattime.c -o proc/whattime.o	
	ar -rc libproc.a proc/*.o top.o

	
