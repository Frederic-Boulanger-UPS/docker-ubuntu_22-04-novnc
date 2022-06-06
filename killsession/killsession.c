#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <errno.h>

int main(int argc, char * argv[]) {
	FILE* sv_pid_file = fopen("/var/run/supervisord.pid", "r");
	if (sv_pid_file != NULL) {
		int pid;
		int r = fscanf(sv_pid_file, "%d", &pid);
		fclose(sv_pid_file);
		if (r == 1) {
			if (kill(pid, SIGTERM) == 0) {
				return EXIT_SUCCESS;
			} else {
				fprintf(stderr, "# Error: could not kill pid %d: error code %d", pid, errno);
				return 1;
			}
		} else {
			fprintf(stderr, "# Error: could not read pid from file \"/var/run/supervisord.pid\"");
			return 1;
		}
	} else {
		fprintf(stderr, "# Error: could not read file \"/var/run/supervisord.pid\"");
		return 1;
	}
}
