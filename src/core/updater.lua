-- Addon global
local TheClassicRace = _G.TheClassicRace

-- deps
local LibWho = LibStub("LibWho-2.0")

-- WoW API
local CreateFrame, GetNumGroupMembers, GetRealZoneText, GetRaidRosterInfo =
_G.CreateFrame, _G.GetNumGroupMembers, _G.GetRealZoneText, _G.GetRaidRosterInfo

---@class TheClassicRaceUpdater
---@field DB table<string, table>
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceUpdater = {}
TheClassicRaceUpdater.__index = TheClassicRaceUpdater
TheClassicRace.Updater = TheClassicRaceUpdater
setmetatable(TheClassicRaceUpdater, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceUpdater.new(Core, DB, EventBus)
    local self = setmetatable({}, TheClassicRaceUpdater)

    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus

    if TheClassicRace.Config.Debug then
        LibWho:SetWhoLibDebug(true)
    end
end

function TheClassicRaceUpdater:DoWho(level)
    LibWho:Who({query = 'lvl-' .. level, queue = LibWho.WHOLIB_QUERY_QUIET, callback = function(query, result, complete)

    end})
end

function TheClassicRaceUpdater:ProcessWhoResult(result)

end

function TheClassicRaceUpdater:Scan()

end