ETCDIR	= /etc
BINDIR	= /sbin
SVDIR	= /etc/sv
MANDIR	= /usr/share/man
VARDIR	= /var
IETCDIR	= $(DESTDIR)$(ETCDIR)
IBINDIR	= $(DESTDIR)$(BINDIR)
ISVDIR	= $(DESTDIR)$(SVDIR)
IMANDIR	= $(DESTDIR)$(MANDIR)
IVARDIR	= $(DESTDIR)$(VARDIR)

CC	= gcc
SCRIPTS	= 1 2 3 ctrlaltdel rc.startup.local rc.shutdown.local rc.startup rc.shutdown
BINARY	= halt pause shutdown
CONF	= modules runit.conf
MAN1	= pause.1
MAN8	= shutdown.8

all:
	$(CC) $(CFLAGS) pause.c -o pause

create-dir:
	install -d $(IETCDIR)/runit/runsvdir/{default,single}
	install -d $(ISVDIR)
	install -d $(IBINDIR)
	install -d $(IMANDIR)/man1
	install -d $(IMANDIR)/man8
	install -d $(IVARDIR)

install: create-dir
	install -m755 $(BINARY) $(IBINDIR)
	ln -sf halt $(IBINDIR)/reboot
	ln -sf halt $(IBINDIR)/poweroff
	install -m755 $(SCRIPTS) $(IETCDIR)/runit
	install -m644 $(CONF) $(IETCDIR)/runit
	install -m644 $(MAN1) $(IMANDIR)/man1/$(MAN1)
	install -m644 $(MAN8) $(IMANDIR)/man8/$(MAN8)
	cp -r services/* $(ISVDIR)
	chmod 755 $(ISVDIR)/*/{run,finish}
	[ -L $(IETCDIR)/runit/runsvdir/current ] || ln -s default $(IETCDIR)/runit/runsvdir/current
	[ -L $(IVARDIR)/service ] || ln -s /etc/runit/runsvdir/current $(IVARDIR)/service
	touch $(IETCDIR)/runit/{reboot,stopit}
	chmod 0 $(IETCDIR)/runit/{reboot,stopit}
	ln -sf /etc/sv/getty-tty1 $(IETCDIR)/runit/runsvdir/default
	ln -sf /etc/sv/sulogin $(IETCDIR)/runit/runsvdir/single

clean:
	rm -f pause

.PHONY: all install clean create-dir
