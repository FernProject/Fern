// This init system should NOT be used on a daily driver, please do not use this on your full installation.
// A seperate, more complete init system will be provided in ferninstall.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>

#define INITP "[ INIT ] "
#define ERRP "[\e[1;31m ERR \e[0m] "

int main() {
	// mount fs
	printf(INITP "Mounting filesystems...\n");
	if (mount("none", "/proc", "proc", MS_NOSUID | MS_NODEV | MS_NOEXEC, NULL) < 0) perror(ERRP "Couldn't mount /proc");
	if (mount("none", "/sys", "sysfs", MS_NOSUID | MS_NODEV | MS_NOEXEC, NULL) < 0) perror(ERRP "Couldn't mount /sys");
	if (mount("none", "/dev", "devtmpfs", MS_NOSUID | MS_NOEXEC, NULL) < 0) perror(ERRP "Couldn't mount /dev");
	mkdir("/dev/pts", 0755);
	if (mount("none", "/dev/pts", "devpts", MS_NOSUID | MS_NOEXEC, NULL) < 0) perror(ERRP "Couldn't mount /dev/pts");
	if (mount("none", "/run", "tmpfs", MS_NOSUID | MS_NODEV | MS_NOEXEC, "mode=0755") < 0) perror(ERRP "Couldn't mount /run");
	
	struct stat efi_stat;
	if (stat("/sys/firmware/efi/efivars", &efi_stat) == 0) {
		if (mount( "none", "/sys/firmware/efi/efivarfs", "efivarfs", MS_NOSUID | MS_NODEV | MS_NOEXEC, NULL) < 0) perror(ERRP "Couldn't mount efivarfs");
	}

	// terminal file descriptors
	int fd = open("/dev/console", O_RDWR);
	if (fd >= 0) {
		dup2(fd, 0); // stdin
		dup2(fd, 1); // stdout
		dup2(fd, 2); // stderr
		if (fd > 2) close(fd);
	}

	printf(INITP "Hello!\n");

	// run shell
	pid_t pid = fork();

	if (pid < 0) perror(ERRP "Couldn't fork");
	else if (pid == 0) {
		// session leadership
		setsid();
		ioctl(0, TIOCSCTTY, 1);

		char* args[] = { "/sbin/agetty", "-8", "115200", "ttyS0", NULL };
		execv(args[0], args);

		perror(ERRP "Couldn't launch agetty");
		exit(1);
	}
	
	else {
		int status;
		while (1) {
			// clean upadopted orphans
			pid_t dead_child = waitpid(-1, &status, 0);

			if (dead_child > 0) {
				if (dead_child == pid) { // session ended
					pid = fork();
					if (pid == 0) {
						setsid();
						ioctl(0, TIOCSCTTY, 1);
						char* args[] = { "/sbin/agetty", "-8", "115200", "ttyS0", NULL };
						execv(args[0], args);
						exit(1);
					}
				}
			}
		}
	}

	return 0;
}