CONFIG= ./config

include $(CONFIG)

SRCS= src/luazip.c
OBJS= src/luazip.o
LIBNAME= zip.so


lib: src/$(LIBNAME)

src/$(LIBNAME): $(OBJS)
	export MACOSX_DEPLOYMENT_TARGET="10.3"; $(CC) $(LIB_OPTION) -o src/$(LIBNAME) $(OBJS) -lzzip

install: src/$(LIBNAME)
	mkdir -p $(LUA_LIBDIR)
	cp src/$(LIBNAME) $(LUA_LIBDIR)/$(LIBNAME)

clean:
	rm -f src/$(LIBNAME) $(OBJS)
