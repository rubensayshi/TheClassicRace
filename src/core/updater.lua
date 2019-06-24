-- Addon global
local TheClassicRace = _G.TheClassicRace

-- Libs
local LibStub = _G.LibStub
local LibWho = LibStub("LibWho-2.0")

-- WoW API
local C_Timer = _G.C_Timer

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

    if TheClassicRace.Config.Debug then
        LibWho:SetWhoLibDebug(true)
    end

    -- we register our callback globally to LibWho so any /who results can be consumed
    LibWho:RegisterCallback("WHOLIB_QUERY_RESULT", function(_, _, result, complete)
        if complete then
            self:ProcessWhoResult(result)
        end
    end)

    return self
end

function TheClassicRaceUpdater:ProcessWhoResult(result)
    -- sort table descending on their level
    table.sort(result, function(a, b)
        return a.Level > b.Level
    end)

    for _, player in ipairs(result) do
        -- Name, Online, Guild, Class, Race, Level, Zone

        self.EventBus:PublishEvent(TheClassicRace.Config.Events.PlayerInfo, player)
    end
end

function TheClassicRaceUpdater:InitTicker()
    if self.Ticker ~= nil then
        return
    end

    self.Ticker = C_Timer.NewTicker(60, function()
        self:StartScan()
    end)
end

function TheClassicRaceUpdater:StartScan()
    -- we don't start another scan when the queue isn't empty yet
    if not LibWho:AllQueuesEmpty() then
        return
    end

    -- don't start a scan if previous is still busy
    if self.Scan ~= nil and not self.Scan:IsDone() then
        return
    end

    local who = function(min, max, cb)
        LibWho:Who(min .. "-" .. max, { queue = LibWho.WHOLIB_QUERY_QUIET, callback = cb })
    end

    self.Scan = TheClassicRace.Scan(self.Core, self.DB, self.EventBus, who)
    self.Scan:Start()
end