.PHONY: tests libs

TESTS ?= .*
INCLUDES ?= tests/* tests/*/*

CLASSIC_INTERFACE = 11302
CLASSIC_VERSION = 1.13.2

setup-dev:
	luarocks install luacheck
	luarocks install busted
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
	test -f libs || make fetch-libs

#
# -- libs --
# to fetch libs we use bw-release.sh dryrun and then copy from the .release folder
#
fetch-libs: download-bw-release
	rm -rf ./libs
	./bw-release.sh -d -u -l -z -g $(CLASSIC_VERSION)
	cp -rf ./.release/TheClassicRace/libs ./libs

#
# -- release --
# multi-step process to build release using bw-release.sh
#
release: download-bw-release
	rm -rf ./.release
	./bw-release.sh -d -u -l -z -g $(CLASSIC_VERSION)   # dry-run release, so we can mutate it afterwards
	sed -i '' 's/src\\dev.lua//g' ./.release/TheClassicRace/TheClassicRace.toc  # take out dev.lua from release .toc
	./bw-release.sh -o -c -u -l -e -d -g $(CLASSIC_VERSION)  # release without copy, reusing our previous done work
