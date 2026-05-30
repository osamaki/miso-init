SHELL := /bin/sh

export LC_ALL := C
export LANG := C

BATS ?=
BREW ?=
BATS_FORMULA ?= bats
TEST_DIR ?= test

FIND_BATS = if [ -n "$(BATS)" ]; then printf '%s\n' "$(BATS)"; elif command -v bats >/dev/null 2>&1; then command -v bats; fi
FIND_BREW = if [ -n "$(BREW)" ]; then printf '%s\n' "$(BREW)"; elif command -v brew >/dev/null 2>&1; then command -v brew; elif [ -x /opt/homebrew/bin/brew ]; then printf '%s\n' /opt/homebrew/bin/brew; elif [ -x /usr/local/bin/brew ]; then printf '%s\n' /usr/local/bin/brew; fi

.PHONY: help setup-test check-bats syntax test check

help:
	@printf '%s\n' 'Targets:'
	@printf '%s\n' '  make setup-test  Install bats with Homebrew when it is missing'
	@printf '%s\n' '  make check-bats  Verify that bats is available'
	@printf '%s\n' '  make syntax      Run bash syntax checks'
	@printf '%s\n' '  make test        Run the bats test suite'
	@printf '%s\n' '  make check       Run syntax checks and tests'

setup-test:
	@bats_bin="$$( $(FIND_BATS) )"; \
	if [ -n "$$bats_bin" ]; then \
		printf 'bats is already available: %s\n' "$$bats_bin"; \
	else \
		brew_bin="$$( $(FIND_BREW) )"; \
		if [ -z "$$brew_bin" ]; then \
			printf '%s\n' 'error: bats is missing and Homebrew was not found.' >&2; \
			printf '%s\n' 'Install Homebrew, or install bats manually.' >&2; \
			exit 1; \
		fi; \
		"$$brew_bin" install "$(BATS_FORMULA)"; \
	fi

check-bats:
	@bats_bin="$$( $(FIND_BATS) )"; \
	if [ -z "$$bats_bin" ]; then \
		printf '%s\n' 'error: bats was not found.' >&2; \
		printf '%s\n' 'Run `make setup-test`, put bats on PATH, or set BATS=/path/to/bats.' >&2; \
		exit 1; \
	fi; \
	printf 'Using bats: %s\n' "$$bats_bin"; \
	"$$bats_bin" --version

syntax:
	env LC_ALL=C LANG=C bash -n bin/miso-init

test: check-bats
	@bats_bin="$$( $(FIND_BATS) )"; \
	env LC_ALL=C LANG=C "$$bats_bin" "$(TEST_DIR)"

check: syntax test
