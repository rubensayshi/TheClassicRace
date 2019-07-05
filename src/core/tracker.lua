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
    EventBus:RegisterCallback(self.Config.Network.Events.PlayerInfo, self, self.OnNetPlayerInfo)
    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.SlashWhoResult, self, self.OnSlashWhoResult)
    EventBus:RegisterCallback(self.Config.Events.ScanFinished, self, self.OnScanFinished)
    EventBus:RegisterCallback(self.Config.Events.LeaderboardSizeDecreased, self, self.OnLeaderboardSizeDecreased)

    return self
end

function TheClassicRaceTracker:OnScanFinished(endofrace)
    -- if a scan finished but the result wasn't complete then we have too many max level players
    if endofrace then
        self:RaceFinished()
    end
end

function TheClassicRaceTracker:OnLeaderboardSizeDecreased()
    -- truncate leaderboard to match size
    while #self.DB.factionrealm.leaderboard > self.DB.profile.options.leaderboardSize do
        table.remove(self.DB.factionrealm.leaderboard)
    end

    self.EventBus:PublishEvent(self.Config.Events.RefreshGUI)
end

function TheClassicRaceTracker:RaceFinished()
    if not self.DB.factionrealm.finished then
        self.DB.factionrealm.finished = true

        self.EventBus:PublishEvent(self.Config.Events.RaceFinished)
    end
end

function TheClassicRaceTracker:OnNetPlayerInfo(playerInfo, _, shouldBroadcast)
    if shouldBroadcast == nil then
        shouldBroadcast = false
    end

    -- the network message is a list so it's future proof if we wanna aggregate
    playerInfo = playerInfo[1]

    self:HandlePlayerInfo({
        name = playerInfo[1],
        level = playerInfo[2],
        dingedAt = playerInfo[3],
    }, shouldBroadcast)
end

function TheClassicRaceTracker:OnSlashWhoResult(playerInfo)
    self:HandlePlayerInfo(playerInfo, true)
end

--[[
HandlePlayerInfo updates the leaderboard and triggers notifications accordingly
]]--
function TheClassicRaceTracker:HandlePlayerInfo(playerInfo, shouldBroadcast)
    -- don't process more player info when we know the race has finished
    if self.DB.factionrealm.finished then
        return
    end

    TheClassicRace:DebugPrint("HandlePlayerInfo: " .. playerInfo.name .. " lvl" .. playerInfo.level)
    -- ignore players below our lower bound threshold
    if playerInfo.level < self.DB.factionrealm.levelThreshold then
        TheClassicRace:DebugPrint("Ignored player info < lvl" .. self.DB.factionrealm.levelThreshold)
        return
    end

    if playerInfo.dingedAt == nil then
        playerInfo.dingedAt = self.Core:Now()
    end

    -- determine where to insert the player and his previous rank
    -- doing this O(n) isn't very efficient, but considering the small size of the leaderboard this is more than fine
    local insertAtRank = nil
    local previousRank = nil
    for rank, player in ipairs(self.DB.factionrealm.leaderboard) do
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
    local isDing = not isNew and playerInfo.level > self.DB.factionrealm.leaderboard[previousRank].level

    -- no change
    if not isNew and not isDing then
        return
    end

    -- grow the leaderboard up until the max size
    if insertAtRank == nil and #self.DB.factionrealm.leaderboard < self.DB.profile.options.leaderboardSize then
        insertAtRank = #self.DB.factionrealm.leaderboard + 1
    end

    -- not high enough for leaderboard
    if insertAtRank == nil then
        return
    end

    -- remove from previous rank
    if previousRank ~= nil then
        table.remove(self.DB.factionrealm.leaderboard, previousRank)
    end

    -- add at new rank
    table.insert(self.DB.factionrealm.leaderboard, insertAtRank, {
        name = playerInfo.name,
        level = playerInfo.level,
        dingedAt = playerInfo.dingedAt,
    })

    -- truncate when leaderboard reached max size
    while #self.DB.factionrealm.leaderboard > self.DB.profile.options.leaderboardSize do
        table.remove(self.DB.factionrealm.leaderboard)
    end

    -- broadcast
    if shouldBroadcast and self.DB.profile.options.networking then
        self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                {{ playerInfo.name, playerInfo.level, playerInfo.dingedAt }, }, "CHANNEL")
        if IsInGuild() then
            self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                    {{ playerInfo.name, playerInfo.level, playerInfo.dingedAt }, }, "GUILD")
        end
    end

    -- publish internal event
    if isNew or isDing then
        self.EventBus:PublishEvent(self.Config.Events.Ding, playerInfo, insertAtRank)
    end

    -- update highest level
    self.DB.factionrealm.highestLevel = math.max(self.DB.factionrealm.highestLevel, playerInfo.level)

    -- we only care about levels >= our bottom ranked on the leaderboard
    if #self.DB.factionrealm.leaderboard >= self.DB.profile.options.leaderboardSize then
        self.DB.factionrealm.levelThreshold = self.DB.factionrealm.leaderboard[#self.DB.factionrealm.leaderboard].level

        if self.DB.factionrealm.levelThreshold == self.Config.MaxLevel then
            self:RaceFinished()
        end
    end
end