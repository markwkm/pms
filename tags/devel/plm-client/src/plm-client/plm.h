#include "log.h"
#include "xml.h"
#include "cmdline.h"

struct {
	char *file;
	char *name;
	char **applies;
	int verbose;
} config;
