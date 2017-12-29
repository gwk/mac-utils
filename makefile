# Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

# $@: The file name of the target of the rule.
# $<: The name of the first prerequisite.
# $^: The names of all the prerequisites, with spaces between them.

.PHONY: _default all build build-rel clean install test

_default: test

all: clean gen build test

swift_build = swift build --build-path _build

build: _build
	$(swift_build)
	@echo done.

build-rel:
	$(swift_build) --configuration release

clean:
	rm -rf _build/*

install: build-rel
	cp _build/x86_64-apple-macosx10.10/release/del /usr/local/bin/

test: build
	iotest -fail-fast

_build:
	mkdir -p $@
