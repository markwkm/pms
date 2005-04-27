#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <libxml/parser.h>
#include <libxml/xmlmemory.h>

#include "plm.h"

static xmlDocPtr XMLDoc = NULL;

#define DOCROOT (xmlDocGetRootElement(XMLDoc))
#define XML_SCHEMA "0.1"

static int checkSchemaVersion(void);
static char *_getValue(xmlNodePtr, char *, char *);
static int _setValue(xmlNodePtr, char *, char *, char *);

void
freeXML(void)
{
	if (XMLDoc != NULL) {
		free(XMLDoc);
		XMLDoc = NULL;
	}
}

int
parseXML(char *data)
{
	int len = strlen(data) + 1;

	if (!data || len < 1)
		return -1;

	freeXML();

	XMLDoc = xmlParseMemory(data, len);

	if (!XMLDoc) {
		log(LOG_ERR, "ERROR Parsing XML Data");
		if (errno)
			perror("xmlParseMemory");
		exit(1);
	}

	if (checkSchemaVersion())
		exit(1);

	return 0;
}

void
newXML(void)
{
	time_t now = time(NULL);

	freeXML();

	XMLDoc = xmlNewDoc("1.0");
	XMLDoc->children = xmlNewDocNode(XMLDoc, NULL, "PLM", NULL);
	xmlNewChild(XMLDoc->children, NULL, "RPC", NULL);

	XMLSetValue("PLM", "Schema", XML_SCHEMA);
	XMLSetValue("PLM", "Generated", ctime(&now));
}

xmlDocPtr
getXML(void)
{
	return XMLDoc;
}

char *
XMLGetValue(char *area, char *token)
{
	log(LOG_DEBUG, "XMLGetValue( %s, %s )", area, token);

	return _getValue(DOCROOT, area, token);
}

static char *
_getValue(xmlNodePtr current, char *area, char *token)
{
	xmlNodePtr node = current;

	while (node) {
		if (!xmlStrcmp(node->name, (const xmlChar *) area))
			return (char *) xmlGetProp(node, token);
		if (node->children)
			return _getValue(node->children, area, token);
		node = node->next;
	}

	log(LOG_DEBUG, "[%p] findNode( %p, %s, %s )", node, current, area,
	    token);

	return NULL;
}

int
XMLSetValue(char *area, char *token, char *value)
{
	log(LOG_DEBUG, "XMLSetValue ( %s, %s, %s )", area, token, value);

	return _setValue(DOCROOT, area, token, value);
}

static int
_setValue(xmlNodePtr current, char *area, char *token, char *value)
{
	xmlNodePtr node = current;
	int notDone = 1;

	while (node && notDone) {
		if (!xmlStrcmp(node->name, (const xmlChar *) area)) {
			xmlSetProp(node, token, value);
			notDone = 0;
		}
		if (node->children && notDone)
			notDone = _setValue(node->children, area, token, value);
		node = node->next;
	}

	return notDone;
}

static int
checkSchemaVersion(void)
{
	char *ver = NULL;
	int verLen, currLen;

	ver = XMLGetValue("PLM", "Schema");
	log(LOG_DEBUG, "xmlGetValue returned [%s]", ver);

	verLen = strlen(ver);
	currLen = strlen(XML_SCHEMA);

	if (verLen == currLen && !strcmp(ver, XML_SCHEMA)) {
		log(LOG_INFO, "Compatible XML Schema Detected");
		free(ver);
		return 0;
	}

	if (ver == NULL)
		ver = strdup("MISSING");

	log(LOG_ERR, "error: incompatible XML Schema version");
	log(LOG_ERR, "Schema is %s, we need %s", ver, XML_SCHEMA);
	free(ver);

	return -1;
}
