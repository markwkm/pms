STAMP = `date '+%s'`
VERSION = 0.0.1

CC = gcc
BIN = plm 
OBJS = cmdline.o xml.o log.o main.o

CFLAGS = -g -Wall \
	-DPLM_VERSION=\"$(VERSION)\" \
	-DSTAMP=\"$(STAMP)\" \
	-D_GNU_SOURCE \
	$(shell xml2-config --cflags) \
	$(shell libwww-config --cflags)
	
LINK=-lcrypt $(shell xml2-config --libs) $(shell libwww-config --libs) 

all:	clean $(BIN)

clean:	
	indent -kr -i8 -ts8 -sob -ss -bs -psl -l80 -lc80 *.c *.h 
	rm -f *~ *.o core $(BIN) plm.1 cmdline.c cmdline.h

%.o:	%.c plm.h
	$(CC) $(CFLAGS) -o $@ -c $<

$(BIN):	clean $(OBJS)
	$(CC) $(CFLAGS) $(LINK) -o $@ $(OBJS)

cmdline.o:	
	clig -d cmdline.cli
	$(CC) $(CFLAGS) cmdline.c -c -o $@ 

dist:
	rm -rf /tmp/plm-$(VERSION) ../../plm-*.tar.bz2
	mkdir -p /tmp/plm-$(VERSION)
	cp -a * /tmp/plm-$(VERSION)
	( cd /tmp/plm-$(VERSION) ; make clean )
	( cd /tmp ; tar -jcf plm-client-$(VERSION).tar.bz2 plm-$(VERSION) )
	mv /tmp/plm-client-$(VERSION).tar.bz2 ../..
	rm -rf /tmp/plm-$(VERSION)

