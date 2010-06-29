#include <syslog.h>
#include <stdarg.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>

#include "plm.h"

// The various log levels
static int STDOUTLevel = 0;
static int STDERRLevel = 0;
static int SYSLOGLevel = 0;

// For auto-init on first call
static int logInit = 0;

int
setLogLevel(char *log, int level)
{
	int logLen;

	logLen = strlen(log);

	if (level < 0 || level > LOG_DEBUG)
		return -1;	// Fail because we didn't find a valid log level

	if (logLen == 6 && !strncmp(log, "STDERR", 6)) {
		STDERRLevel = level;
		return 0;
	}

	if (logLen == 6 && !strncmp(log, "STDOUT", 6)) {
		STDOUTLevel = level;
		return 0;
	}

	if (logLen == 6 && !strncmp(log, "SYSLOG", 6)) {
		SYSLOGLevel = level;
		return 0;
	}

	return -1;		// Fail because we didn't find a valid log target
}

void
log(int level, char *format, ...)
{
	va_list ap;
	char txt[MAX_LOG];
	int len;

	// Init the syslog if we have not been called before
	if (logInit == 0) {
		openlog("PLM", LOG_CONS | LOG_PID, LOG_LOCAL5);
		logInit = 1;
	}
	// Gather the actual log format and content
	va_start(ap, format);
	len = vsnprintf(txt, MAX_LOG, format, ap);
	if ((len < 0) || (len > MAX_LOG))
		return;
	va_end(ap);

	// Process STDERR
	if (STDERRLevel >= level)
		fprintf(stderr, "%s\n", txt);

	// Process STDOUT
	if (STDOUTLevel >= level)
		fprintf(stdout, "%s\n", txt);

	// Process SYSLOG
	if (SYSLOGLevel >= level)
		syslog(level, "%s", txt);
}
