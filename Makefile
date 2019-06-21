.PHONY: tests

TESTS ?= .*
INCLUDES ?= tests/* tests/*/*

setup-dev:
	luarocks install luacheck
	luarocks install busted
	luarocks install cluacov || luarocks install luacov

hr:
	@echo "======================================================================================"
	@echo "======================================================================================"

lint:
	luacheck ./src

tests:
	busted --coverage \
	-m './src/?.lua;./src/?/?.lua;./src/?/init.lua;./libs/?.lua;./libs/?/?.lua;./tests/?.lua;./tests/?/?.lua' \
	$(INCLUDES) --filter='$(TESTS)'

reflex-tests:
	reflex -r '.*\.lua' -s  -- sh -c 'make hr lint tests'
