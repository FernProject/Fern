# compile src/ programmes

CC = gcc
CFLAGS = -Wall -Wextra -O2 -g -std=c11
BFS = basefs
B = base

all: copy compile coreutils

copy:
	cp -r $(B) $(BFS)

# all src/* goes here
compile: src/testprogram.c
	$(CC) $(CFLAGS) src/testprogram.c -o basefs/bin/testprogram

# gets and install gnu coreutils
coreutils: copy
	mkdir coreutils
	wget https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz
	mv coreutils-9.12.tar.xz coreutils/coreutils912.tar.xz
	tar -xf coreutils/coreutils912.tar.xz
	mv coreutils-9.12 coreutils/coreutils

clean:
	rm -rf $(BFS)
	rm -rf coreutils

.PHONY: all start coreutils clean