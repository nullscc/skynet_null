.PHONY: all skynet clean proto cjson
PLAT ?= linux
ROOT ?= $(shell pwd)

all : skynet 3rd

skynet/Makefile :
	git submodule update --init --recursive

skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT)

# protoc请先自行编译安装好
3rd : proto cjson

proto : 
	cd $(ROOT)/3rd/pbc && $(MAKE)
	sed -i "s/LUADIR = .*/LUADIR = ..\/..\/..\/..\/skynet\/3rd\/lua/g" $(ROOT)/3rd/pbc/binding/lua53/Makefile
	cd $(ROOT)/3rd/pbc/binding/lua53 && $(MAKE) && cp protobuf.so $(ROOT)/luaclib && cp protobuf.lua $(ROOT)/lualib
	chmod +x $(ROOT)/proto/protogenpb.sh
	$(ROOT)/proto/protogenpb.sh

cjson :
	sed -i "s/PREFIX =            .*/PREFIX =            ..\/..\/skynet\/3rd\/lua/g" $(ROOT)/3rd/cjson/Makefile
	sed -i "s/LUA_INCLUDE_DIR =   .*/LUA_INCLUDE_DIR =            $$\(PREFIX\)/g" $(ROOT)/3rd/cjson/Makefile
	sed -i "s/LUA_CMODULE_DIR =   .*/LUA_CMODULE_DIR =            $$\(PREFIX\)/g" $(ROOT)/3rd/cjson/Makefile
	sed -i "s/LUA_MODULE_DIR =   .*/LUA_MODULE_DIR =            $$\(PREFIX\)/g" $(ROOT)/3rd/cjson/Makefile
	sed -i "s/LUA_BIN_DIR =   .*/LUA_BIN_DIR =            $$\(PREFIX\)/g" $(ROOT)/3rd/cjson/Makefile
	cd $(ROOT)/3rd/cjson && $(MAKE) && cp cjson.so $(ROOT)/luaclib

clean :
	cd skynet && $(MAKE) clean
	cd $(ROOT)/3rd/pbc/binding/lua53 && $(MAKE) clean
	cd $(ROOT)/3rd/pbc && $(MAKE) clean
	cd $(ROOT)/3rd/cjson && $(MAKE) clean