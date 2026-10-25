// This init system was thrown together in an hour, it should NOT be used on a daily driver, please do not use this on your full installation.
// A seperate, more complete init system is provided in ferninstall.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>

#include "additional.h"

int main() {
	// terminal file descriptors
	int fd = open("/dev/console", O_RDWR);
	if (fd >= 0) {
		dup2(fd, 0); // stdin
		dup2(fd, 1); // stdout
		dup2(fd, 2); // stderr
		if (fd > 2) close(fd);
	}

	printf("\n"INITP "Hello!\n");

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

	// chosen shell /bin/sh if no conf file
	char sshell[pathmax] = "/bin/sh";
	rconf(sshell); // fetch chosen shell

	printf(INITP "Found shell: %s\n", sshell);



	// run bash - or whichever shell u want
	printf(INITP "Starting shell...\n");
	printf("\n" INITP "Welcome to Fern!\n")

	pid_t pid = fork();

	if (pid < 0) perror(ERRP "Couldn't fork shell");
	else if (pid == 0) {
		// session leadership
		setsid();
		ioctl(0, TIOCSCTTY, 1);

		char* args[] = { sshell, NULL };
		execv(args[0], args);

		// cant start shell
		perror(ERRP "Couldn't launch shell");
		exit(1);
	}
	
	else {
		int status;
		while (1) {
			// clean upadopted orphans
			pid_t dead_child = waitpid(-1, &status, 0);

			if (dead_child > 0) {
				// if main shell crashes: clone
				if (dead_child == pid) {
					printf(ERRP "Shell crashed! :( ... Respawning %s...\n", sshell);
					pid = fork();
					if (pid == 0) {
						setsid();
						ioctl(0, TIOCSCTTY, 1);
						char* args[] = { sshell, NULL };
						execv(args[0], args);
						exit(1);
					}
				}
			}
		}
	}

	return 0;
}