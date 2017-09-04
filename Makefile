# $Id: Makefile,v 1.10 2006-07-24 01:24:36 tomas Exp $

T= zip
V= 1.2.3
CONFIG= ./config

include $(CONFIG)

SRCS= src/lua$T.c
OBJS= src/lua$T.o


lib: src/$(LIBNAME)

src/$(LIBNAME): $(OBJS)
	export MACOSX_DEPLOYMENT_TARGET="10.3"; $(CC) $(CFLAGS) $(LIB_OPTION) -o src/$(LIBNAME) $(OBJS) -lzzip

install: src/$(LIBNAME)
	mkdir -p $(LUA_LIBDIR)
	cp src/$(LIBNAME) $(LUA_LIBDIR)/$T.so

clean:
	rm -f $L src/$(LIBNAME) $(OBJS)
