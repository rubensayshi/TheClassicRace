# WoW Addon: The Classic Race
This is a WoW addon to keep track of the top 50 players on your realm in the race to lvl60!

[![Coverage Status](https://coveralls.io/repos/github/rubensayshi/TheClassicRace/badge.svg)](https://coveralls.io/github/rubensayshi/TheClassicRace)

## Dev Setup
```bash
# make sure you have `luarocks`, `luacov` and `busted` installed, you can install them easily with:
make setup-dev
```

## Libs
WoW Addon libs is a mess ... you can fetch them with:
```bash
make libs
```

## Testing
```bash
# to run test suite and linter:
make lint tests

# if you have `reflex` installed (https://github.com/cespare/reflex) you can use this to retry tests on file change:
make reflex-tests

# you can specify a subset of the tests to run with TESTS var, like;
make reflex-tests TESTS=tests/util/util.lua
```

## Structure
We're trying to avoid using globals as much as possible, so all components are bound to our addon global `TheClassicRace`  
and we generally pass components to other components that depend on them at initialization.  
The only `TheClassicRace.` or `TheClassicRace:` access should be for `Config` and the `*Print` methods.

For some decoupling we can use the `EventBus` to propagate events as well...
