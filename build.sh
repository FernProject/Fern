#!/bin/bash
set -e

USER="fernuser"
PASSWD="fernos"
ROOT="fernos"

B="base"
BFS="basefs"
BU="build"
WS=$(pwd)


echo "Build is still in the process of being completed. Running now will not result in a finished system. Exiting..."
exit 0

# copy base
rm -rf "$BFS"
cp -r "$B" "$BFS"
find "$BFS" -type f -name ".gitkeep" -delete

# compile src
echo "compiling src/*"
cd "$WS"
make src

# init
echo "compiling init"
cd "$WS"
make init
cat << EOF > "$BFS/etc/init.conf"
# init config

#provide a shell path
SHELL=/bin/bash # installed with Fern

# other shells:
# SHELL=/bin/sh # Fern symlinks this to /bin/bash
# SHELL=/bin/zsh
EOF

# bash
# dont redownload if alr exists
if [ ! -f "$BU/bash-5.3" ]; then
	echo "downloading Bash 5.3..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
	tar -xf "$WS/$BU/bash-5.3.tar.gz" -C "$WS/$BU"
	cd "$WS/$BU/bash-5.3"
	./configure --prefix="$WS/$BFS" --bindir="$WS/$BFS/usr/bin"
	make -j$(nproc)
fi

# always reinstall
cd "$WS/$BU/bash-5.3"
make install
cd "$WS/$BFS/bin"
ln -sf bash sh
cd "$WS"
rm -rf "$BFS/include" "$BFS/share"


# coreutils
if [ ! -f "$BU/coreutils-9.12" ]; then
	echo "download Coreutils..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz
	tar -xf "$BU/coreutils-9.12.tar.xz" -C "$WS/$BU"
	cd "$WS/$BU/coreutils-9.12"
	./configure --prefix="$WS/$BFS" \
				--bindir="$WS/$BFS/usr/bin" \
				--sbindir="$WS/$BFS/usr/sbin" \
				--libdir="$WS/$BFS/usr/lib"
	make -j$(nproc)
fi

cd "$WS/$BU/coreutils-9.12"
make install
cd "$WS"
rm -rf "$WS/$BFS/libexec" "$WS/$BFS/share"