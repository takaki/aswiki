# -*- Makefile -*-

# $Format: "VERSION = $ProjectVersion$"$
VERSION = 1.1.4

all:

setup:
	-mkdir -p RCS
	-mkdir -p session
	-mkdir -p cache
	-mkdir -p attach
	-mkdir -p text
	 # -chmod 777 RCS session cache attach text
clean:
	find -name '*~' |xargs rm -f

dist: clean
	shtool tarball -d aswiki-$(VERSION) -c gzip -o ../aswiki-$(VERSION).tar.gz .