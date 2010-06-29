#include <libxml/parser.h>

extern void newXML(void);
extern xmlDocPtr getXML(void);
extern int parseXML(char *);
extern void freeXML(void);
extern char *XMLGetValue(char *, char *);
extern int XMLSetValue(char *, char *, char *);
