-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local IsInGuild = _G.IsInGuild

--[[
Tracker is responsible for maintaining our leaderboard data based on data provided by other parts of the system
to us through the EventBus.
]]--
---@class TheClassicRaceTracker
---@field DB table<string, table>
---@field Config TheClassicRaceConfig
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
---@field Network TheClassicRaceNetwork
---@field lbGlobal TheClassicRaceLeaderboard
---@field lbPerClass table<string, TheClassicRaceLeaderboard>
local TheClassicRaceTracker = {}
TheClassicRaceTracker.__index = TheClassicRaceTracker
TheClassicRace.Tracker = TheClassicRaceTracker
setmetatable(TheClassicRaceTracker, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceTracker.new(Config, Core, DB, EventBus, Network)
    local self = setmetatable({}, TheClassicRaceTracker)

    self.Config = Config
    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus
    self.Network = Network

    self.lbGlobal = TheClassicRace.Leaderboard(self.Config, self.DB.factionrealm.leaderboard[0])
    self.lbPerClass = {}
    for classIndex, _ in ipairs(self.Config.Classes) do
        self.lbPerClass[classIndex] = TheClassicRace.Leaderboard(self.Config, self.DB.factionrealm.leaderboard[classIndex])
    end

    -- subscribe to network events
    EventBus:RegisterCallback(self.Config.Network.Events.PlayerInfoBatch, self, self.OnNetPlayerInfoBatch)
    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.SlashWhoResult, self, self.OnSlashWhoResult)
    EventBus:RegisterCallback(self.Config.Events.SyncResult, self, self.OnSyncResult)
    EventBus:RegisterCallback(self.Config.Events.ScanFinished, self, self.OnScanFinished)

    return self
end

function TheClassicRaceTracker:OnScanFinished(endofrace)
    -- if a scan finished but the result wasn't complete then we have too many max level players
    if endofrace then
        self:RaceFinished()
    end
end

function TheClassicRaceTracker:CheckRaceFinished()
    local raceFinished = true
    for _, lbdb in pairs(self.DB.factionrealm.leaderboard) do
        if lbdb.minLevel < self.Config.MaxLevel then
            raceFinished = false
            break
        end
    end

    if raceFinished then
        self:RaceFinished()
    end
end

function TheClassicRaceTracker:RaceFinished()
    if not self.DB.factionrealm.finished then
        self.DB.factionrealm.finished = true

        self.EventBus:PublishEvent(self.Config.Events.RaceFinished)
    end
end

function TheClassicRaceTracker:OnNetPlayerInfoBatch(payload, _, shouldBroadcast)
    -- ignore data received when we've disabled networking
    if not self.DB.profile.options.networking then
        return
    end

    if shouldBroadcast == nil then
        shouldBroadcast = false
    end

    local batchstr = payload[1]
    local isRebroadcast = payload[2]
    local classIndex = payload[3] or 0

    local batch = TheClassicRace.Serializer.DeserializePlayerInfoBatch(batchstr)

    self:ProcessPlayerInfoBatch(batch, shouldBroadcast, false, classIndex)

    -- if it wasn't a rebroadcast then it was a /who scan, we can delay our own /who scan a bit
    if not isRebroadcast then
        self.EventBus:PublishEvent(self.Config.Events.BumpScan, classIndex)
    end
end

function TheClassicRaceTracker:OnSlashWhoResult(playerInfoBatch, classIndex)
    self:ProcessPlayerInfoBatch(playerInfoBatch, true, false, classIndex)
end

function TheClassicRaceTracker:OnSyncResult(playerInfoBatch, shouldBroadcast)
    self:ProcessPlayerInfoBatch(playerInfoBatch, shouldBroadcast, true)
end

function TheClassicRaceTracker:ProcessPlayerInfoBatch(playerInfoBatch, shouldBroadcast, isRebroadcast, classIndex)
    local batch = {}

    -- the network message can be a list of playerInfo
    local changed
    for _, playerInfo in ipairs(playerInfoBatch) do
        playerInfo, changed = self:ProcessPlayerInfo(playerInfo)

        -- if anything was updated then we add the player to the batch to broadcast
        if changed then
            table.insert(batch, playerInfo)
        end
    end

    -- broadcast
    if shouldBroadcast and #batch > 0 and self.DB.profile.options.networking then
        local serializedBatch = TheClassicRace.Serializer.SerializePlayerInfoBatch(batch)

        self.Network:SendObject(self.Config.Network.Events.PlayerInfoBatch,
                { serializedBatch, isRebroadcast, classIndex }, "CHANNEL")
        if IsInGuild() then
            self.Network:SendObject(self.Config.Network.Events.PlayerInfoBatch,
                    { serializedBatch, isRebroadcast, classIndex }, "GUILD")
        end
    end
end

--[[
ProcessPlayerInfo updates the leaderboard and triggers notifications accordingly
]]--
function TheClassicRaceTracker:ProcessPlayerInfo(playerInfo)
    -- don't process more player info when we know the race has finished
    if self.DB.factionrealm.finished then
        return
    end

    TheClassicRace:DebugPrint("[T] ProcessPlayerInfo: [" .. tostring(playerInfo.classIndex) .. "][" .. tostring(playerInfo.class) .. "] "
            .. playerInfo.name .. " lvl" .. playerInfo.level)

    if playerInfo.dingedAt == nil then
        playerInfo.dingedAt = self.Core:Now()
    end

    if playerInfo.classIndex == nil and playerInfo.class ~= nil then
        playerInfo.classIndex = self.Core:ClassIndex(playerInfo.class)
        playerInfo.class = nil
    end

    TheClassicRace:DebugPrint("[T] ProcessPlayerInfo: [" .. tostring(playerInfo.classIndex) .. "][" .. tostring(playerInfo.class) .. "] "
            .. playerInfo.name .. " lvl" .. playerInfo.level)

    local globalRank, globalIsChanged = self.lbGlobal:ProcessPlayerInfo(playerInfo)
    local classRank, classIsChanged, classLowestLevel = nil, nil
    if playerInfo.classIndex ~= nil then
        classRank, classIsChanged, classLowestLevel = self.lbPerClass[playerInfo.classIndex]:ProcessPlayerInfo(playerInfo)
    end

    -- publish internal event
    if globalIsChanged or classIsChanged then
        self.EventBus:PublishEvent(self.Config.Events.Ding, playerInfo, globalRank, classRank)
    end

    -- check if the race is finished if the class leaderboard is finished
    if classLowestLevel == self.Config.MaxLevel then
        self:CheckRaceFinished()
    end

    -- return normalized playerinfo and boolean if anything changed
    return playerInfo, globalIsChanged or classIsChanged
end