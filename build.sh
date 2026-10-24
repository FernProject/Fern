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

echo "Writing /etc files"
echo "/etc/passwd"
cat << EOF > "$WS/$BFS/etc/passwd"
root:x:0:0:root:/root:/bin/sh
$USER:x:1000:1000:$USER:/bin/sh
bin:x:1:1:bin:/bin/false
daemon:x:2:2:daemon:/sbin:/bin/false
nobody:x:65534:65534:nobody:/bin:/bin/false
EOF

echo "/etc/shadow"
cat << EOF > "$WS/$BFS/etc/shadow"
root:$(openssl passwd -6 "$ROOT"):19000:0:99999:7:::
$USER:$(openssl passwd -6  "$PASSWD"):19000:0:99999:7:::
EOF

echo "/etc/group"
cat << EOF > "$WS/$BFS/etc/group"
root:x:0:root
$USER:x:1000:
bin:x:1:bin
daemon:x:2:daemon
sys:x:3:
tty:x:5:
nobody:x:65534
EOF

echo "/etc/fstab"
cat << EOF > "$WS/$BFS/etc/fstab
#<fs> 		<mount pt> 	<type> <options> 	<dump> <pass>
none		/proc		proc	defaults		0	0
none		/sys		sysfs	defaults		0	0
none		/run		tmpfs	defaults,mode=0755	0	0
none		/dev/pts	devpts	defaults		0	0