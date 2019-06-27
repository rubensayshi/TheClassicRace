-- Addon global
local TheClassicRace = _G.TheClassicRace

-- Libs
local LibStub = _G.LibStub
local LibWho = LibStub("LibWho-2.0")

-- WoW API
local C_Timer, CreateFrame = _G.C_Timer, _G.CreateFrame

--[[
Updater is responsible for periodically doing a Scan to get updated results
and relaying that back to the rest of the system through the EventBus

This is also the place where we have the LibWho specific code, so it's not being unittested atm ...
so it would be good if we can keep it small
]]--
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
    self.Ticker = nil
    self.Scan = nil

    if TheClassicRace.Config.Trace then
        LibWho:SetWhoLibDebug(true)
    end

    -- we register our callback globally to LibWho so any /who results can be consumed
    LibWho:RegisterCallback("WHOLIB_QUERY_RESULT", function(_, _, result, complete)
        if complete then
            self:ProcessWhoResult(result)
        end
    end)

    -- create a Frame to use as thread to receive events on
    self.Thread = CreateFrame("Frame")
    self.Thread:Hide()
    self.Thread:SetScript("OnEvent", function(_, event, ...)
        if (event == "PLAYER_LEVEL_UP") then
            self:OnPlayerLevelUp(...)
        end
    end)

    -- register for level up events
    self.Thread:RegisterEvent("PLAYER_LEVEL_UP")

    return self
end
function TheClassicRaceUpdater:OnPlayerLevelUp(level)
    TheClassicRace:DebugPrint("OnPlayerLevelUp(" .. tostring(level) .. ")")

    -- we fake an /who result
    self.EventBus:PublishEvent(TheClassicRace.Config.Events.SlashWhoResult, {
        name = self.Core:Me(),
        level = level,
    })
end

function TheClassicRaceUpdater:ProcessWhoResult(result)
    -- filter out nils, seems to be a possibility ...
    result = TheClassicRace.list.filter(result, function (player)
        return player ~= nil and player.Name ~= nil and player.Level ~= nil
    end)

    -- sort table descending on their level to make sure we don't announce multiple leaders from 1 result
    -- @TODO: need to write test for this
    if #result > 1 then
        table.sort(result, function(a, b)
            return a.Level > b.Level
        end)
    end

    for _, player in ipairs(result) do
        -- Name, Online, Guild, Class, Race, Level, Zone
        local name = self.Core:SplitFullPlayer(player.Name)

        self.EventBus:PublishEvent(TheClassicRace.Config.Events.SlashWhoResult, {
            name = name,
            level = player.Level,
        })
    end
end

function TheClassicRaceUpdater:InitTicker()
    -- don't setup ticker when we know the race has finished
    if self.DB.realm.finished then
        return
    end

    if self.Ticker ~= nil then
        return
    end

    self.Ticker = C_Timer.NewTicker(60, function()
        self:StartScan()
    end)
end

function TheClassicRaceUpdater:StartScan()
    -- don't scan when we know the race has finished
    if self.DB.realm.finished then
        return
    end

    -- we don't start another scan when the queue isn't empty yet
    if not LibWho:AllQueuesEmpty() then
        TheClassicRace:DebugPrint("StartScan but LibWho not ready")
        return
    end

    -- don't start a scan if previous is still busy
    if self.Scan ~= nil and not self.Scan:IsDone() then
        TheClassicRace:DebugPrint("StartScan but scan still in progress")
        return
    end

    local who = function(min, max, cb)
        LibWho:Who(min .. "-" .. max, { queue = LibWho.WHOLIB_QUERY_QUIET, callback = cb })
    end

    local min = self.DB.realm.levelThreshold
    local max = TheClassicRace.Config.MaxLevel

    self.Scan = TheClassicRace.Scan(self.Core, self.DB, self.EventBus, who, min, max)
    self.Scan:Start()
end