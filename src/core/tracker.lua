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

    self.throttles = {}

    -- subscribe to network events
    EventBus:RegisterCallback(self.Config.Network.Events.PlayerInfo, self, self.OnPlayerInfo)
    EventBus:RegisterCallback(self.Config.Network.Events.RequestUpdate, self, self.OnRequestUpdate)
    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.SlashWhoResult, self, self.OnSlashWhoResult)
    EventBus:RegisterCallback(self.Config.Events.ScanFinished, self, self.OnScanFinished)

    return self
end

function TheClassicRaceTracker:RequestUpdate()
    -- don't request updates when we know the race has finished
    if self.DB.realm.finished then
        return
    end

    -- request update over guild and channel
    self.Network:SendObject(self.Config.Network.Events.RequestUpdate, {}, "CHANNEL")
    if IsInGuild() then
        self.Network:SendObject(self.Config.Network.Events.RequestUpdate, {}, "GUILD")
    end
end

function TheClassicRaceTracker:OnRequestUpdate(_, sender)
    TheClassicRace:DebugPrint("Update Requested")

    -- if we don't know a leader yet then we can't respond
    if #self.DB.realm.leaderboard == 0 then
        TheClassicRace:DebugPrint("Update Requested, but no leader")
        return
    end

    -- cleanup throttle list
    local now = self.Core:Now()
    for _, throttle in ipairs(self.throttles) do
        if throttle.time + TheClassicRace.Config.Throttle <= now then
            table.remove(self.throttles, 1)
        else
            break
        end
    end

    -- check if sender is still in throttle window
    for _, throttle in ipairs(self.throttles) do
        if throttle.sender == sender then
            TheClassicRace:TracePrint("throttled " .. sender)
            return
        end
    end

    -- add sender to throttle list
    table.insert(self.throttles, {sender = sender, time = now})

    -- respond with leader
    self.Network:SendObject(self.Config.Network.Events.PlayerInfo, {
        self.DB.realm.leaderboard[1].name,
        self.DB.realm.leaderboard[1].level,
        self.DB.realm.leaderboard[1].dingedAt
    }, "WHISPER", sender)
end

function TheClassicRaceTracker:OnScanFinished(complete)
    -- if a scan finished but the result wasn't complete then we have too many max level players
    if not complete then
        self:RaceFinished()
    end
end

function TheClassicRaceTracker:RaceFinished()
    if not self.DB.realm.finished then
        self.DB.realm.finished = true

        self.EventBus:PublishEvent(self.Config.Events.RaceFinished)
    end
end

function TheClassicRaceTracker:OnPlayerInfo(playerInfo)
    self:HandlePlayerInfo({
        name = playerInfo[1],
        level = playerInfo[2],
        dingedAt = playerInfo[3],
    }, false)
end

function TheClassicRaceTracker:OnSlashWhoResult(playerInfo)
    self:HandlePlayerInfo(playerInfo, true)
end

--[[
HandlePlayerInfo updates the leaderboard and triggers notifications accordingly
]]--
function TheClassicRaceTracker:HandlePlayerInfo(playerInfo, shouldBroadcast)
    -- don't process more player info when we know the race has finished
    if self.DB.realm.finished then
        return
    end

    TheClassicRace:DebugPrint("HandlePlayerInfo: " .. playerInfo.name .. " lvl" .. playerInfo.level)
    -- ignore players below our lower bound threshold
    if playerInfo.level < self.DB.realm.levelThreshold then
        TheClassicRace:DebugPrint("Ignored player info < lvl" .. self.DB.realm.levelThreshold)
        return
    end

    local now = self.Core:Now()
    local dingedAt = playerInfo.DingedAt
    if dingedAt == nil then
        dingedAt = now
    end

    -- determine where to insert the player and his previous rank
    -- doing this O(n) isn't very efficient, but considering the small size of the leaderboard this is more than fine
    local insertAtRank = nil
    local previousRank = nil
    for rank, player in ipairs(self.DB.realm.leaderboard) do
        -- find the place where to insert the new player
        if insertAtRank == nil and playerInfo.level > player.level then
            insertAtRank = rank
        end

        -- find a possibly previous entry of this player
        if previousRank == nil and playerInfo.name == player.name then
            previousRank = rank
        end
    end

    local isNew = previousRank == nil
    local isDing = not isNew and playerInfo.level > self.DB.realm.leaderboard[previousRank].level

    -- no change
    if not isNew and not isDing then
        return
    end

    -- grow the leaderboard up until the max size
    if insertAtRank == nil and #self.DB.realm.leaderboard < self.Config.LeaderboardSize then
        insertAtRank = #self.DB.realm.leaderboard + 1
    end

    -- not high enough for leaderboard
    if insertAtRank == nil then
        return
    end

    -- remove from previous rank
    if previousRank ~= nil then
        table.remove(self.DB.realm.leaderboard, previousRank)
    end

    -- add at new rank
    table.insert(self.DB.realm.leaderboard, insertAtRank, {
        name = playerInfo.name,
        level = playerInfo.level,
        dingedAt = dingedAt,
    })

    -- truncate when leaderboard reached max size
    if not previousRank and #self.DB.realm.leaderboard > self.Config.LeaderboardSize then
        table.remove(self.DB.realm.leaderboard)
    end

    -- broadcast
    if shouldBroadcast then
        self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                { playerInfo.name, playerInfo.level, dingedAt }, "CHANNEL")
        if IsInGuild() then
            self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                    { playerInfo.name, playerInfo.level, dingedAt }, "GUILD")
        end
    end

    -- publish internal event
    if isNew or isDing then
        self.EventBus:PublishEvent(self.Config.Events.Ding, playerInfo, insertAtRank)
    end

    -- update highest level
    self.DB.realm.highestLevel = math.max(self.DB.realm.highestLevel, playerInfo.level)

    -- we only care about levels >= our bottom ranked on the leaderboard
    if #self.DB.realm.leaderboard >= self.Config.LeaderboardSize then
        self.DB.realm.levelThreshold = self.DB.realm.leaderboard[#self.DB.realm.leaderboard].level

        if self.DB.realm.levelThreshold == self.Config.MaxLevel then
            self:RaceFinished()
        end
    end
end