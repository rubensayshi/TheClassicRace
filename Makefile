.PHONY: tests libs

TESTS ?= .*
INCLUDES ?= tests/* tests/*/*

ifneq ($(UPLOADRELEASE),)
RELEASEARGS ?=
else
RELEASEARGS ?= -d
endif

setup-dev:
	luarocks install luacheck
	luarocks install busted 2.0.rc13-0
	luarocks install cluacov || luarocks install luacov

hr:
	@echo "======================================================================================"
	@echo "======================================================================================"

lint:
	luacheck ./src

tests: libs
	busted --coverage \
	-m './src/?.lua;./src/?/?.lua;./src/?/init.lua;./libs/?.lua;./libs/?/?.lua;./tests/?.lua;./tests/?/?.lua' \
	$(INCLUDES) --filter='$(TESTS)'

reflex-tests:
	reflex -r '.*\.lua' -s  -- sh -c 'make hr lint tests'

#
# -- download-bw-release --
# fetch the release.sh script from bigwigs
#
download-bw-release:
	test -f bw-release.sh \
    || wget -O bw-release.sh https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh \
    && chmod +x bw-release.sh

#
# -- libs --
# to fetch libs we use bw-release.sh dryrun and then copy from the .release folder
#
libs:
	test -d ./libs || make fetch-libs

#
# -- libs --
# to fetch libs we use bw-release.sh dryrun and then copy from the .release folder
#
fetch-libs: download-bw-release
	rm -rf ./libs
	./bw-release.sh -d -u -l -z
	cp -rf ./.release/TheClassicRace/libs ./libs

#
# -- release --
# multi-step process to build release using bw-release.sh
#
release: download-bw-release
	rm -rf ./.release
	./bw-release.sh -u -l $(RELEASEARGS)
