# compile src/ programmes

CC = gcc
CFLAGS = -Wall -Wextra -O2 -g -std=c11
BFS = basefs
B = base

all: copy compile bash coreutils

copy:
	cp -r $(B) $(BFS)
	find $(BFS) -type f -name ".gitkeep" -delete

# all src/* goes here
compile: src/testprogram.c
	$(CC) $(CFLAGS) src/testprogram.c -o basefs/bin/testprogram


# gets and installs bash !!!!!!!!
bash: copy
	mkdir -p bash
	wget -nc -P bash https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
	tar -xf bash/bash-5.3.tar.gz -C bash


# gets and installs gnu coreutils
coreutils: copy
	mkdir -p cu
	wget -nc -P cu https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz
	tar -xf cu/coreutils-9.12.tar.xz -C cu
	
	cd cu/coreutils-9.12 && ./configure --prefix=$$(cd ../../$(BFS) && pwd) \
										--bindir=$$(cd ../../$(BFS) && pwd)/usr/bin \
										--sbindir=$$(cd ../../$(BFS) && pwd)/usr/sbin \
										--libdir=$$(cd ../../$(BFS) && pwd)/usr/lib
	cd cu/coreutils-9.12 && make -j$$(nproc)
	cd cu/coreutils-9.12 && make install


# setup etc files
etc: copy
	echo "root:x:0:0:root:/root:/bin/sh"


clean:
	rm -rf $(BFS)
	rm -rf bash
	rm -rf cu

.PHONY: all start bash coreutils etc clean