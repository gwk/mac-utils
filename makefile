# Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

# $@: The file name of the target of the rule.
# $<: The name of the first prerequisite.
# $^: The names of all the prerequisites, with spaces between them.

.PHONY: _default build build-rel clean install test

_default: test


build:
	swift build
	@echo build done.

build-rel:
	swift build --configuration release
	@echo build-rel done.

clean:
	rm -rf _build/*

install: build-rel
	cp .build/release/{del,gen-thumbnails,zapple} /usr/local/bin/
	cp notify.py /usr/local/bin/notify

test: build
	iotest -fail-fast
