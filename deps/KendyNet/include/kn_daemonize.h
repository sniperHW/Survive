#ifndef _KN_DAEMONIZE_H
#define _KN_DAEMONIZE_H
#include <syslog.h>
#include <fcntl.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <sys/stat.h>
#include <signal.h>

void daemonize(const char *cmd);
int already_running(void);
void set_lockfile(const char *lockfile);
void set_workdir(const char *workdir);

#endif
