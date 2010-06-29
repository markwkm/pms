#include <syslog.h>

#define MAX_LOG 200

extern void log(int, char *, ...);
extern int setLogLevel(char *, int);
