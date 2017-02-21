# Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

# $@: The file name of the target of the rule.
# $<: The name of the first prerequisite.
# $^: The names of all the prerequisites, with spaces between them.

.PHONY: _default all build clean cov test xcode

_default: test

all: clean gen build test

swift_build = swift build --build-path _build

# src/Lex.swift
build:
	$(swift_build)
	@echo done.

clean:
	rm -rf _build/*

cov:
	$(swift_build) -Xswiftc -profile-coverage-mapping -Xswiftc -profile-generate

test: build
	iotest -fail-fast

xcode:
	swift package generate-xcodeproj

_build:
	mkdir -p $@
