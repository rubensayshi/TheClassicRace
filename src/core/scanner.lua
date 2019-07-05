-- Addon global
local TheClassicRace = _G.TheClassicRace

-- Libs
local LibStub = _G.LibStub
local LibWho = LibStub("LibWho-2.0")

-- WoW API
local C_Timer, CreateFrame = _G.C_Timer, _G.CreateFrame

--[[
Scanner is responsible for periodically doing a Scan to get updated results
and relaying that back to the rest of the system through the EventBus

This is also the place where we have the LibWho specific code, so it's not being unittested atm ...
so it would be good if we can keep it small
]]--
---@class TheClassicRaceScanner
---@field DB table<string, table>
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceScanner = {}
TheClassicRaceScanner.__index = TheClassicRaceScanner
TheClassicRace.Scanner = TheClassicRaceScanner
setmetatable(TheClassicRaceScanner, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceScanner.new(Core, DB, EventBus)
    local self = setmetatable({}, TheClassicRaceScanner)

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

    -- subscribe to local events
    EventBus:RegisterCallback(TheClassicRace.Config.Events.BumpScan, self, self.OnBumpScan)

    return self
end

function TheClassicRaceScanner:OnPlayerLevelUp(level)
    TheClassicRace:DebugPrint("OnPlayerLevelUp(" .. tostring(level) .. ")")

    -- we fake an /who result
    self.EventBus:PublishEvent(TheClassicRace.Config.Events.SlashWhoResult, {{
        name = self.Core:Me(),
        level = level,
        class = self.Core:MyClass(),
    }, })
end

function TheClassicRaceScanner:ProcessWhoResult(result)
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

    local batch = {}
    for idx, player in ipairs(result) do
        -- Name, Online, Guild, Class, Race, Level, Zone
        local name = self.Core:SplitFullPlayer(player.Name)

        batch[idx] = {
            name = name,
            level = player.Level,
            -- @TODO: this is localized so only works on english atm
            class = string.upper(player.Class),
        }
    end

    self.EventBus:PublishEvent(TheClassicRace.Config.Events.SlashWhoResult, batch)
end

function TheClassicRaceScanner:InitTicker()
    -- don't setup ticker when we know the race has finished
    if self.DB.factionrealm.finished then
        return
    end

    if self.Ticker ~= nil then
        return
    end

    -- random offset just so that not everyone who logs in after a server restart is completely synced up
    local randomOffset = math.random(0, 10)

    self.Ticker = C_Timer.NewTicker(60 + randomOffset, function()
        self:StartScan()
    end)
end

function TheClassicRaceScanner:OnBumpScan()
    -- don't bump ticker when we know the race has finished
    if self.DB.realm.finished then
        return
    end
    -- don't bump ticker when we configured it not to
    if self.DB.profile.options.dontbump then
        return
    end

    -- weird, but if this is the case then there's nothing to bump
    if self.Ticker == nil then
        return
    end

    -- don't bump the ticker if the scan scan is in progress
    if self.Scan ~= nil and not self.Scan:IsDone() then
        return
    end

    -- cancel the current ticker
    self.Ticker:Cancel()

    -- init a new ticker
    self:InitTicker()
end

function TheClassicRaceScanner:StartScan()
    -- don't scan when we know the race has finished
    if self.DB.factionrealm.finished then
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

    local min = self.DB.factionrealm.levelThreshold
    local prevhighestlvl = self.DB.factionrealm.highestLevel
    local max = TheClassicRace.Config.MaxLevel

    self.Scan = TheClassicRace.Scan(self.Core, self.DB, self.EventBus, who, min, prevhighestlvl, max)
    self.Scan:Start()
end