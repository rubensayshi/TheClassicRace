# WoW Addon: The Classic Race
This is a WoW addon to keep track of the top 50 players on your realm in the race to lvl60!

[![Coverage Status](https://coveralls.io/repos/github/rubensayshi/TheClassicRace/badge.svg)](https://coveralls.io/github/rubensayshi/TheClassicRace)

![demo](https://raw.githubusercontent.com/rubensayshi/TheClassicRace/master/demo.png)

## Releases
For latest releases that you can just unzip into your `Interface\Addons` folder, 
please download from CurseForge or WoWInterface:
 - Curse: https://www.curseforge.com/wow/addons/the-classic-race
 - WoWInterface: https://www.wowinterface.com/downloads/info25052-TheClassicRace.html

## Dev Setup
If you want to keep your lua project envs seperated take a look at `hererocks` (used in `.travis.yml` as well).

```bash
# make sure you have `luarocks`, `luacov` and `busted` installed, you can install them easily with:
make setup-dev
```

## Libs
WoW Addon depedency ecosystem is a mess ... we'll just use the release script to fetch the deps, 
you can fetch them with:
```bash
# only downloads if no `./libs` exists
make libs

# always downloads fresh copy
make fetch-libs
```

## Testing
```bash
# to run test suite and linter:
make lint tests

# if you have `reflex` installed (https://github.com/cespare/reflex) you can use this to retry tests on file change:
make reflex-tests

# you can specify a subset of the test files to run with INCLUDES var, like;
make reflex-tests INCLUDES=scan.lua

# or a name of a test with with TESTS var, like;
make reflex-tests TESTS='.*too many max lvl.*'
```

Test coverage is a bit a lie ... it only shows coverage for the files included in the testsuite run,  
but we don't include `main.lua`, `options.lua`, `scanner.lua` and the `gui/*.lua` files...  

The other stuff is well covered and we <3 mocks.

## Structure
We're trying to avoid using globals as much as possible, so all components are bound to our addon global `TheClassicRace`  
and we generally pass components to other components that depend on them at initialization.  
The only `TheClassicRace.` or `TheClassicRace:` access should be for `Config` and the `*Print` methods.

For some decoupling we can use the `EventBus` to propagate events as well...

We don't write unittests for `main.lua`, `options.lua`, `scanner.lua` and the `gui/*.lua` files, 
because they're so highly dependant on so many libs which in turn are so highly dependent on so many WoW API methods 
that we'd have to mock way to many things...  
For this reason we try to avoid too much logic in these places!
