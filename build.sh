#!/bin/bash
set -e

USER="fernuser"
PASSWD="fernos"
ROOT="fernos"

B="base"
BFS="basefs"
BU="build"
WS=$(pwd)

# copy base
rm -rf "$BFS" "$BU"
cp -r "$B" "$BFS"
find "$BFS" -type f -name ".gitkeep" -delete


# make iso build dir for later
mkdir -p "$WS/$BU/img"


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
	echo "Downloading Glibc..."
	mkdir -p "$WS/$BU"
	mkdir -p "$WS/$BU/glibc-build" # mk separate build dir
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/glibc/glibc-2.44.tar.xz
	tar -xf "$BU/glibc-2.44.tar.xz" -C "$WS/$BU"
	cd "$WS/$BU/glibc-build"
	
	../glibc-2.44/configure --prefix="/usr" \
							--bindir="/usr/bin" \
							--sbindir="/usr/sbin" \
							--libdir="/usr/lib" \
							--libexecdir="/usr/libexec" \
							--with-headers="$WS/$BFS/usr/include" \
							lib_cv_slibdir="/usr/lib" \
							lib_cv_rtlddir="/usr/lib"
	make -j$(nproc)
fi
cd "$WS/$BU/glibc-build"
make install DESTDIR="$WS/$BFS"
cd "$WS"



# coreutils
if [ ! -f "$WS/$BU/coreutils-9.12" ]; then
	echo "Downloading Coreutils..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/coreutils/coreutils-9.12.tar.xz
	tar -xf "$BU/coreutils-9.12.tar.xz" -C "$WS/$BU"
	cd "$WS/$BU/coreutils-9.12"
	./configure --prefix="/usr" \
				--bindir="/usr/bin" \
				--sbindir="/usr/sbin" \
				--libdir="/usr/lib" \
				--libexecdir="/usr/libexec"
	make -j$(nproc)
fi
cd "$WS/$BU/coreutils-9.12"
make install DESTDIR="$WS/$BFS"
cd "$WS"

# bash
if [ ! -f "$WS/$BU/bash-5.3" ]; then
	echo "Downloading Bash 5.3..."
	mkdir -p "$WS/$BU"
	wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz
	tar -xf "$WS/$BU/bash-5.3.tar.gz" -C "$WS/$BU"
	cd "$WS/$BU/bash-5.3"
	./configure --prefix="/usr" \
				--bindir="/usr/bin" \
				--enable-static-link \
				WITHOUT_CURSES=libtinfo
	make -j$(nproc)
fi
cd "$WS/$BU/bash-5.3"
make install DESTDIR="$WS/$BFS"
cd "$WS/$BFS/bin"
ln -sf bash sh
cd "$WS"

# util linux - will add support later
#if [ ! -f "$WS/$BU/util-linux-2.42.4" ]; then
#	echo "Downloading util-linux"
#	mkdir -p "$WS/$BU"
#	wget -nc -P "$WS/$BU" https://www.kernel.org/pub/linux/utils/util-linux/v2.42/util-linux-2.42.4.tar.xz
#	tar -xf "$WS/$BU/util-linux-2.42.4.tar.xz" -C "$WS/$BU"
#	cd "$WS/$BU/util-linux-2.42.4"
#	./configure --prefix="/usr" \
#				--bindir="/usr/bin" \
#				--sbindir="/usr/sbin" \
#				--libdir="/usr/lib" \
#				--disable-makeinstall-chown \
#				--disable-makeinstall-setuid \
#				--disable-cramfs \
#				CC="gcc --sysroot=$WS/$BFS" \
#				CFLAGS="-I$WS/$BFS/usr/include" \
#				LDFLAGS="-L$WS/$BFS/usr/lib -Wl,-rpath-link,$WS/$BFS/usr/lib"
#	make -j$(nproc)
#fi
#cd "$WS/$BU/util-linux-2.42.4"
#make install DESTDIR="$WS/$BFS"
cd "$WS"

# compile src
echo "Compiling src/*"
cd "$WS"
make src


# kernel
cd "$WS/$BU/linux-7.2.12"
make defconfig
make -j$(nproc)
make INSTALL_MOD_PATH="$WS/$BFS" modules_install
cp "$WS/$BU/linux-7.2.12/arch/x86/boot/bzImage" "$WS/$BU/img/vmlinuz" # install to iso build dir


# init
echo "Compiling init"
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


# tbh i found the whole grub part confusing with initramfs - probably isnt perfect
# grub bootloader
echo "Downloading GRUB"
mkdir -p "$WS/$BU"
wget -nc -P "$WS/$BU" https://ftp.gnu.org/gnu/grub/grub-2.14.tar.xz
tar -xf "$WS/$BU/grub-2.14.tar.xz" -C "$WS/$BU"
mkdir -p "$WS/$BU/build-bios"
mkdir -p "$WS/$BU/build-uefi"

# grub for bios
cd "$WS/$BU/build-bios"
../grub-2.14/configure --prefix="/usr" \
						--bindir="/usr/bin" \
						--sbindir="/usr/sbin" \
						--sysconfdir="/etc" \
						--with-platform=pc \
						--target=i386 \
						--disable-werror \
						TARGET_LDFLAGS="-fuse-ld=bfd" \
						ax_cv_check_ldflags___Wl___image_base_0x400000=no
make -j$(nproc)
make install DESTDIR="$WS/$BFS"

# grub for uefi
cd "$WS/$BU/build-uefi"
../grub-2.14/configure --prefix="/usr" \
						--bindir="/usr/bin" \
						--sbindir="/usr/sbin" \
						--sysconfdir="/etc" \
						--with-platform=efi \
						--target=x86_64 \
						--disable-werror \
						TARGET_LDFLAGS="-fuse-ld=bfd"
make -j$(nproc)
make install DESTDIR="$WS/$BFS"

cd "$WS"
rm -rf "$WS/$BFS/usr/share/info"


 make img ----
read -p "Writing ISO, continue? [Y/n]: " continue
case "$continue" in
	[nN][oO]|[nN])
		echo "Quit. Please note, build is incomplete. All components are inside basefs, excluding:"
		echo "    * Linux | build/img/vmlinuz"
		echo "    * GRUB cfg file | not written"
		exit 1
		;;
	*)
esac

mkdir -p "$WS/$BU/img/boot/grub"
mkdir -p "$WS/$BU/iso"

# write conf file
cat << EOF > "$WS/$BU/img/boot/grub/grub.cfg"
# Hi!
set timeout=5
set default=0

serial --unit=0 --speed=115200
terminal_input serial
terminal_output serial

menuentry "Fern Live Media (RAM)" {
	# lets us see kernel init logs
	linux /vmlinuz root=/dev/ram0 rw init=/init console=ttyS0 Earlyprintk=serial,ttyS0,115200
	initrd /initramfs.cpio.gz
}
EOF

# basefs -> initramfs
echo "Making initramfs"
cd "$WS/$BFS"
find . -print0 | cpio --null -ov --format=newc | gzip -9 > "$WS/$BU/img/initramfs.cpio.gz"
cd "$WS"

echo "Building ISO"
grub-mkrescue -o "$WS/$BU/iso/fernos_live.iso" "$WS/$BU/img"

echo "Finished"
