-- stubs
require("stubs.misc")
require("stubs.player")
require("stubs.createframe")
require("stubs.chatinfo")

-- libs loaded with dofile() because dots in the names ...
dofile("libs/LibStub/LibStub.lua")
dofile("libs/CallbackHandler/CallbackHandler-1.0.lua")
dofile("libs/AceDB/AceDB-3.0.lua")
dofile("libs/AceSerializer/AceSerializer-3.0.lua")
dofile("libs/AceComm/ChatThrottleLib.lua")
dofile("libs/AceComm/AceComm-3.0.lua")
--require("libs/LibWho-2.0/LibWho-2.0.lua")

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
require("core.broadcaster")
require("networking.network")

return TheClassicRace
