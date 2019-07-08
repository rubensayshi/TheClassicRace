.PHONY: tests libs

TESTS ?= .*
INCLUDES ?= .*
EXCLUDES ?= libcompressmock.lua
TESTOPTS ?=

# if UPLOADRELEASE is set to anything (y, n, maybe, w/e) then we do -d during the `release` step
# which will attempt to upload the release
ifneq ($(UPLOADRELEASE),)
RELEASEARGS ?=
else
RELEASEARGS ?= -d
endif

#
# -- setup-dev --
# install our development depedencies using luarocks
#
setup-dev:
	luarocks install luacheck
	luarocks install busted 2.0.rc13-0
	luarocks install cluacov || luarocks install luacov

#
# -- hr --
# simply helper to print some spacer
#
hr:
	@echo "======================================================================================"
	@echo "======================================================================================"

#
# -- lint --
# run luacheck on source code
#
lint:
	luacheck ./src

#
# -- tests --
# run our testsuite using busted
# include path is a bit of a messy thing, but it works ...
#
# using TESTS you can provide a filter on test NAMES to run
# using INCLUDES you can provide a filter on test FILES to run
#
#
tests: libs
	busted --coverage \
	-m './src/?.lua;./src/?/?.lua;./src/?/init.lua;./libs/?.lua;./libs/?/?.lua;./tests/?.lua;./tests/?/?.lua' \
	$(TESTOPTS) \
	--pattern='$(INCLUDES)' \
	--exclude-pattern='$(EXCLUDES)' \
	tests/ tests/util/ --filter='$(TESTS)'

#
# -- tests --
# using reflex watch our source code and rerun the testsuite whenever something is changed
# TESTS, INCLUDES, EXCLUDES will be passed down if you set them
#
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
# checks if ./libs exists, otherwise downloads
#
libs:
	test -d ./libs || make fetch-libs

#
# -- libs --
# to fetch libs we use bw-release.sh with some flags that disable everything except downloading externals
# and then copy from the .release folder
#
fetch-libs: download-bw-release
	rm -rf ./libs
	./bw-release.sh -d -u -l -z
	cp -rf ./.release/TheClassicRace/libs ./libs

#
# -- release --
# build release using bw-release.sh
# depending on $(RELEASEARGS) it will or will not upload (see above)
#
release: download-bw-release
	rm -rf ./.release
	./bw-release.sh -u -l $(RELEASEARGS)
