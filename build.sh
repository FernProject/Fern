# so, i realise i need to make a few changes to things before this can become an iso:
#
# - move kernel into an iso build dir
# - install grub into iso build dir
# - pack basefs into initramfs
# - THEN make iso
#
# will do tomorrow :)

#!/bin/bash
set -e

USER="fernuser"
PASSWD="fernos"
ROOT="fernos"

B="base"
BFS="basefs"
BU="build"
WS=$(pwd)

#echo "Build is still in the process of being completed. Running now will not result in a finished system. Exiting..."
#exit 0

# copy base
rm -rf "$BFS" "$BU"
cp -r "$B" "$BFS"
find "$BFS" -type f -name ".gitkeep" -delete


# kernel headers
if [ ! -f "$WS/$BU/linux-7.2.12" ]; then
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-7.2.12.tar.xz
	tar -xf "$WS/$BU/linux-7.2.12.tar.xz" -C "$WS/$BU"
fi
cd "$WS/$BU/linux-7.2.12"
make mrproper
make INSTALL_HDR_PATH="$WS/$BFS/usr" headers_install
cd "$WS"

# glibc
if [ ! -f "$WS/$BU/glibc-2.44" ]; then
	echo "downloading Glibc..."
	mkdir -p "$WS/$BU"
	mkdir -p "$WS/$BU/glibc-build" # mk separate build dir
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/glibc/glibc-2.44.tar.xz
	tar -xf "$BU/glibc-2.44.tar.xz" -C "$WS/$BU"
	cd "$WS/$BU/glibc-build"
	
	../glibc-2.44/configure --prefix="$WS/$BFS" \
							--bindir="$WS/$BFS/usr/bin" \
							--sbindir="$WS/$BFS/usr/sbin" \
							--libdir="$WS/$BFS/usr/lib" \
							--libexecdir="$WS/$BFS/usr/libexec" \
							--with-headers="$WS/$BFS/usr/include" \
							lib_cv_slibdir="$WS/$BFS/usr/lib" \
							lib_cv_rtlddir="$WS/$BFS/usr/lib"
	make -j$(nproc)
fi
cd "$WS/$BU/glibc-build"
make install
cd "$WS"



# coreutils
if [ ! -f "$WS/$BU/coreutils-9.12" ]; then
	echo "downloading Coreutils..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz
	tar -xf "$BU/coreutils-9.12.tar.xz" -C "$WS/$BU"
	cd "$WS/$BU/coreutils-9.12"
	./configure --prefix="$WS/$BFS" \
				--bindir="$WS/$BFS/usr/bin" \
				--sbindir="$WS/$BFS/usr/sbin" \
				--libdir="$WS/$BFS/usr/lib" \
				--libexecdir="$WS/$BFS/usr/libexec"
	make -j$(nproc)
fi
cd "$WS/$BU/coreutils-9.12"
make install
cd "$WS"
rm -rf "$WS/$BFS/libexec" "$WS/$BFS/share"

# bash
# dont redownload if alr exists
if [ ! -f "$WS/$BU/bash-5.3" ]; then
	echo "downloading Bash 5.3..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
	tar -xf "$WS/$BU/bash-5.3.tar.gz" -C "$WS/$BU"
	cd "$WS/$BU/bash-5.3"
	./configure --prefix="$WS/$BFS" --bindir="$WS/$BFS/usr/bin"
	make -j$(nproc)
fi
cd "$WS/$BU/bash-5.3"
make install
cd "$WS/$BFS/bin"
ln -sf bash sh
cd "$WS"
rm -rf "$BFS/include" "$BFS/share"

# compile src
echo "compiling src/*"
cd "$WS"
make src


# kernel
cd "$WS/$BU/linux-7.2.12"
make defconfig
make -j$(nproc)
make INSTALL_MOD_PATH="$WS/$BFS" modules_install
cp "$WS/$BU/linux-7.2.12/arch/x86/boot/bzImage" "$WS/$BFS/boot/vmlinuz"


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



# etc
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
cat << EOF > "$WS/$BFS/etc/fstab"
#<fs> 		<mount pt> 	<type> <options> 	<dump> <pass>
none		/proc		proc	defaults		0	0
none		/sys		sysfs	defaults		0	0
none		/run		tmpfs	defaults,mode=0755	0	0
none		/dev/pts	devpts	defaults		0	0
EOF

echo "Network config"
printf "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n" > "$WS/$BFS/etc/hosts"

# get host nameserver
HOST_NS=$(awk '/nameserver/ {print $2; exit}' /etc/resolv.conf)
# fallback
if [ -z "$HOST_NS" ]; then
	HOST_NS="1.1.1.1"
fi
echo "nameserver $HOST_NS" > "$WS/$BFS/etc/resolv.conf"
echo "Fern" > "$WS/$BFS/etc/hostname"

echo "/etc/profile"
cat << 'EOF' > "$WS/$BFS/etc/profile"
export PATH=/usr/bin:/usr/sbin:/bin:/sbin

if [ "$USER" = "root" ]; then
    export PS1='\u@fernos:\w\# '
else
    export PS1='\u@fernos:\w\$ '
fi

export USER=$(id -un)
export LOGNAME=$USER
export HOME=/root
EOF

# grub bootloader
echo "downloading GRUB"
mkdir -p "$WS/$BU"
wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/grub/grub-2.14.tar.xz
tar -xf "$WS/$BU/grub-2.14.tar.xz" -C "$WS/$BU"
mkdir -p "$WS/$BFS/boot/grub"

cd "$WS/$BU/grub-2.14"

# grub for bios
./configure --prefix="$WS/$BFS" \
			--bindir="$WS/$BFS/usr/bin" \
			--sbindir="$WS/$BFS/usr/sbin" \
			--libdir="$WS/$BFS/usr/lib" \
			--sysconfdir="$WS/$BFS/etc" \
			--with-platform=pc \
			--target=i386 \
			--disable-werror
make -j$(nproc)
make install DESTDIR="$WS/$BFS"

# grub for uefi
./configure --prefix="$WS/$BFS" \
			--bindir="$WS/$BFS/usr/bin" \
			--sbindir="$WS/$BFS/usr/sbin" \
			--libdir="$WS/$BFS/usr/lib" \
			--sysconfdir="$WS/$BFS/etc" \
			--with-platform=efi \
			--target=x86_64 \
			--disable-werror
cd "$WS"
rm -rf "$WS/$BFS/usr/share/info"

# write conf file
cat << EOF > "$WS/$BFS/boot/grub/grub.cfg"
# Hi!
set timeout=5
set default=0

menuentry "Fern Live Media" {
	linux /boot/vmlinuz root=/dev/ram0 rw init=/init
}
EOF
