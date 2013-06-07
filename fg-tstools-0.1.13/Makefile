exec_prefix = $(prefix)
libdir = $(exec_prefix)/lib/tstools
bindir = $(exec_prefix)/bin

build:
		echo 'build'
install:
		mkdir -p $(DESTDIR)/$(libdir)/
		mkdir -p $(DESTDIR)/$(bindir)/
		mkdir -p $(DESTDIR)/etc/
		cp ts_functions.sh $(DESTDIR)/$(libdir)/
		cp ts_network_backup_functions.sh $(DESTDIR)/$(libdir)/
		cp ts_exclude.txt $(DESTDIR)/$(libdir)/
		cp ts_getid $(DESTDIR)/$(bindir)/
		cp ts_identify_backups $(DESTDIR)/$(bindir)/
		cp ts_mount $(DESTDIR)/$(bindir)/
		cp ts_network_backup $(DESTDIR)/$(bindir)/
		cp ts_rechown $(DESTDIR)/$(bindir)/
		cp ts_network_backup.cfg $(DESTDIR)/etc/

uninstall:
		rm -r $(DESTDIR)/$(libdir)/
		rm $(DESTDIR)/$(bindir)/ts_getid
		rm $(DESTDIR)/$(bindir)/ts_identify_backups
		rm $(DESTDIR)/$(bindir)/ts_mount
		rm $(DESTDIR)/$(bindir)/ts_network_backup
		rm $(DESTDIR)/$(bindir)/ts_rechown

