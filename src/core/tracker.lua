-- Addon global
local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceTracker
---@field DB table<string, table>
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
    EventBus:RegisterCallback(self.Config.Network.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(self.Config.Network.Events.RequestUpdate, self, self.OnRequestUpdate)
    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.PlayerInfo, self, self.OnPlayerInfo)

    return self
end

function TheClassicRaceTracker:RequestUpdate()
    -- request update over guild and channel
    self.Network:SendObject(self.Config.Network.Events.RequestUpdate, {}, "GUILD")
    self.Network:SendObject(self.Config.Network.Events.RequestUpdate, {}, "CHANNEL")
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
    self.Network:SendObject(self.Config.Network.Events.Ding, {
        self.DB.realm.leaderboard[1].name,
        self.DB.realm.leaderboard[1].level,
        self.DB.realm.leaderboard[1].dingedAt
    }, "WHISPER", sender)
end

function TheClassicRaceTracker:OnDing(playerInfo)
    self:HandlePlayerInfo({
        name = playerInfo[1],
        level = playerInfo[2],
        dingedAt = playerInfo[3],
    }, false)
end

function TheClassicRaceTracker:OnPlayerInfo(playerInfo)
    self:HandlePlayerInfo(playerInfo, true)
end

--[[
HandlePlayerInfo updates the leaderboard and triggers notifications accordingly
]]--
function TheClassicRaceTracker:HandlePlayerInfo(playerInfo, shouldBroadcast)
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
        self.Network:SendObject(self.Config.Network.Events.Ding,
                { playerInfo.name, playerInfo.level, dingedAt }, "CHANNEL")
        self.Network:SendObject(self.Config.Network.Events.Ding,
                { playerInfo.name, playerInfo.level, dingedAt }, "GUILD")
    end

    -- new highest level! implies ding
    if playerInfo.level > self.DB.realm.highestLevel then
        self.DB.realm.highestLevel = playerInfo.level

        -- @TODO: move out of tracker
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("The race is over! Gratz to " .. playerInfo.name .. ", first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", " ..
            "first to reach level " .. playerInfo.level .. "!")
        end
    elseif isDing then
        TheClassicRace:PPrint("Gratz to " .. playerInfo.name .. ", reached level " .. playerInfo.level .. "! " ..
        "Currently rank #" .. insertAtRank .. "in the race!")
    end

    -- we only care about levels >= our bottom ranked on the leaderboard
    self.DB.realm.levelThreshold = self.DB.realm.leaderboard[#self.DB.realm.leaderboard].level
end