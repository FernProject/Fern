CC = gcc
CFLAGS = -Wall -Wextra -O2 -g -std=c11
BFS = basefs

make:
	@echo "THIS FILE SHOULD NOT BE EXECUTED!"
	@echo "Please read the README to understand the build process."
	@echo ""
	@echo "This file is to be used by build.sh, to compile components at the correct time during the build process."
	@echo "Running any targets inside of this file outside of the automated build script will break your build!"
	@echo "INSTEAD, run \`./build.sh\`"



init:
	$(CC) $(CFLAGS) -c src/init/init.c -o src/init/init.o
	$(CC) $(CFLAGS) -c src/init/additional.c src/init/additional.o
	$(CC) $(CFLAGS) src/init/init.o src/init/init.c -o basefs/init

src:
	$(CC) $(CFLAGS) src/ferninstall/ferninstall.c -o $(BFS)/bin/ferninstall
	$(CC) $(CFLAGS) src/testprogramme.c -o $(BFS)/bin/testprogramme

clean:
	rm -rf basefs bash cu kernel grub
	find . -type f -name "*.o" -delete