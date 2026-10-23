#include "additional.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>

void trim(char* out, const char* in) {
	while (isspace((unsigned char)*in)) in++;
	size_t len = strlen(in);
	while (len > 0 && isspace((unsigned char)in[len - 1])) len--;
	strncpy(out, in, len);
	out[len] = '\0';
}

void rconf(char* path) {
	FILE* file = fopen("/etc/init.conf", "r");
	if (file == NULL) { // no init.conf
		printf(WARNP "Couldn't find config file or is empty (/etc/init.conf). Falling back to /bin/sh\n");
		// make file for future
		FILE* mkfile = fopen("/etc/init.conf", "w");
		fprintf(mkfile, "# init config\n\n" \
						"# provide a shell path\n" \
						"SHELL=/bin/bash # installed with Fern\n\n" \
						"# other shells:\n" \
						"# SHELL=/bin/sh # Fern symlinks this to /bin/bash\n" \
						"# SHELL=/bin/zsh\n" );
		fflush(mkfile);
		fclose(mkfile);
		return;
	}

	char line[512];
	while (fgets(line, sizeof(line), file)) {
		// skip comment or empty
		if (line[0] == '#' || line[0] == '\n'|| line[0] == '\r') continue;

		char* split = strchr(line, '=');
		if (split != NULL) {
			*split = '\0';

			char key[256];
			char val[256];
			trim(key, line);
			trim(val, split + 1);
		
			if (strcmp(key, "SHELL") == 0) {
				strncpy(path, val, pathmax - 1);
				path[pathmax - 1] = '\0';
				break;
			}
		}
	}
	printf(INITP "Found shell!\n");
	fclose(file);
}