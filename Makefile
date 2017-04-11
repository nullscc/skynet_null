.PHONY: all skynet clean proto
PLAT ?= linux
ROOT ?= $(shell pwd)

all : skynet 3rd

skynet/Makefile :
	git submodule update --init --recursive

skynet : skynet/Makefile
	cd skynet && $(MAKE) $(PLAT)

# protoc请先自行编译安装好
3rd : proto

proto : 
	cd $(ROOT)/3rd/pbc && $(MAKE)
	cd $(ROOT)/3rd/pbc/binding/lua53 && $(MAKE) && cp protobuf.so $(ROOT)/luaclib && cp protobuf.lua $(ROOT)/lualib
	chmod +x $(ROOT)/proto/protogenpb.sh
	$(ROOT)/proto/protogenpb.sh

clean :
	cd skynet && $(MAKE) clean