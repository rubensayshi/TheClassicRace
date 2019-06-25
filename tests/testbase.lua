-- stubs
require("stubs.misc")
require("stubs.player")
require("stubs.createframe")
require("stubs.chatinfo")
-- libs
require("LibStub")
require("AceDB-3dot0.AceDB-3dot0")
require("AceSerializer-3dot0.AceSerializer-3dot0")
--require("LibWho-2dot0.LibWho-2dot0")

-- addon
TheClassicRace = {}
_G.TheClassicRace = TheClassicRace

require("config")
require("defaultdb")
require("util.chat")
require("util.util")
require("util.list-helpers")
require("util.table-helpers")
require("core.core")
require("core.event-bus")
require("core.scan")
require("core.tracker")
require("networking.network")

return TheClassicRace
