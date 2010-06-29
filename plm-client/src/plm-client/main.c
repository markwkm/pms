#include <stdlib.h>
#include <stdio.h>

#include "plm.h"

int loadConfig(int argc, char **argv);
void parseLogLevels(Cmdline * cmd);
void parseRequiredOptions(Cmdline * cmd);

void
parseLogLevels(Cmdline * cmd)
{
	int level = LOG_NOTICE;

	if (cmd->verboseP)
		level = LOG_INFO;

	if (cmd->debugP)
		level = LOG_DEBUG;

	if (cmd->quietP)
		setLogLevel("STDOUT", 0);
	else
		setLogLevel("STDOUT", level);

	if (cmd->syslogP)
		setLogLevel("SYSLOG", level);
	else
		setLogLevel("SYSLOG", 0);

	setLogLevel("STDERR", 0);
}

void
parseRequiredOptions(Cmdline * cmd)
{
	if (!cmd->filenameP)
		config.filename = getPLMFilename();
	else
		config.filename = strdup(cmd->filename);

	if (!cmd->appliesP)
		config.applies = getPLMApplies();
	else
		config.applies = cmd->applies;

	if (!cmd->nameP)
		config.name = getPLMName();
	else
		config.name = strdup(cmd->name);
}

int
loadConfig(int argc, char **argv)
{
	Cmdline *cmd = parseCmdline(argc, argv);

	if (cmd->helpP) {
		printf("\n");
		usage();
		exit(EXIT_SUCCESS);
	}

	parseLogLevels(cmd);
	if (parseRequiredOptions(cmd) != 0) {
		log(LOG_CRIT, "");
		usage();
		return -1;
	}

	return 0;
}

int
main(int argc, char **argv)
{
	if (loadConfig(argc, argv) == -1)
		return EXIT_FAILURE;

	log(LOG_NOTICE, "Patch Lifecycle Manager Client");
	log(LOG_INFO, "V%s [build: %s]", PLM_VERSION, STAMP);

	return EXIT_SUCCESS;
}
