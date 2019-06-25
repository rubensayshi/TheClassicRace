-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local CreateFrame = _G.CreateFrame

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

function TheClassicRaceTracker.new(Core, DB, EventBus, Network)
    local self = setmetatable({}, TheClassicRaceTracker)

    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus
    self.Network = Network

    self.throttle = {}

    -- @TODO: do we need the frame?
    self.Frame = CreateFrame("Frame")
    self.Frame:SetScript("OnEvent", function()
    end)

    -- subscribe to network events
    EventBus:RegisterCallback(TheClassicRace.Config.Network.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(TheClassicRace.Config.Network.Events.RequestUpdate, self, self.OnRequestUpdate)
    -- subscribe to local events
    EventBus:RegisterCallback(TheClassicRace.Config.Events.PlayerInfo, self, self.OnPlayerInfo)

    return self
end

function TheClassicRaceTracker:RequestUpdate()
    -- request update over guild and channel
    self.Network:SendObject(TheClassicRace.Config.Network.Events.RequestUpdate, {}, "GUILD")
    self.Network:SendObject(TheClassicRace.Config.Network.Events.RequestUpdate, {}, "CHANNEL")
end

function TheClassicRaceTracker:OnRequestUpdate(_, sender)
    TheClassicRace:DebugPrint("Update Requested")
    -- if we don't know a leader yet then we can't respond
    if self.DB.realm.leader == nil then
        TheClassicRace:DebugPrint("Update Requested, but no leader")
        return
    end

    -- cleanup throttle list
    local now = self.Core:Now()
    for _, throttle in ipairs(self.throttle) do
        if throttle.time + TheClassicRace.Confg.Throttle < now then
            table.remove(self.throttle, 1)
        else
            break
        end
    end

    -- check if sender is still in throttle window
    for _, throttle in ipairs(self.throttle) do
        if throttle.sender == sender then
            return
        end
    end

    -- add sender to throttle list
    self.throttle.insert({Sender = sender, Time = now})

    -- respond with leader
    self.Network:SendObject(TheClassicRace.Config.Network.Events.Ding, self.DB.realm.leader, "WHISPER", sender)
end

function TheClassicRaceTracker:OnDing(playerInfo)
    self:HandlePlayerInfo({
        Name = playerInfo[1],
        Level = playerInfo[2],
        DingedAt = playerInfo[3],
    }, false)
end

function TheClassicRaceTracker:OnPlayerInfo(playerInfo)
    self:HandlePlayerInfo(playerInfo, true)
end

function TheClassicRaceTracker:OnMaxLevelBump()
    -- we only care about >= highest level - 10
    self.DB.realm.levelThreshold = math.max(
            self.DB.realm.levelThreshold,
            self.DB.realm.highestLevel - 10
    )

    -- clean our DB of lower level records
    for playerName, playerInfo in pairs(self.DB.realm.players) do
        if playerInfo.level < self.DB.realm.levelThreshold then
            self.DB.realm.players[playerName] = nil
        end
    end
end

function TheClassicRaceTracker:HandlePlayerInfo(playerInfo, shouldBroadcast)
    TheClassicRace:DebugPrint("HandlePlayerInfo: " .. playerInfo.Name .. " lvl" .. playerInfo.Level)
    -- ignore players below our lower bound threshold
    if playerInfo.Level < self.DB.realm.levelThreshold then
        TheClassicRace:DebugPrint("Ignored player info < lvl" .. self.DB.realm.levelThreshold)
        return
    end

    local now = self.Core:Now()
    local dingedAt = playerInfo.DingedAt
    if dingedAt == nil then
        dingedAt = now
    end
    local isNew = self.DB.realm.players[playerInfo.Name].level == nil
    local isDing = not isNew and playerInfo.Level > self.DB.realm.players[playerInfo.Name].level

    -- store player info
    self.DB.realm.players[playerInfo.Name].level = playerInfo.Level
    self.DB.realm.players[playerInfo.Name].lastseenAt = now
    if isDing or isNew then
        self.DB.realm.players[playerInfo.Name].dingedAt = dingedAt

        -- broadcast new/ding
        if shouldBroadcast then
            self.Network:SendObject(TheClassicRace.Config.Network.Events.Ding,
                    { playerInfo.Name, playerInfo.Level, dingedAt }, "CHANNEL")
            self.Network:SendObject(TheClassicRace.Config.Network.Events.Ding,
                    { playerInfo.Name, playerInfo.Level, dingedAt }, "GUILD")
        end
    end

    -- new highest level! implies ding
    if playerInfo.Level > self.DB.realm.highestLevel then
        self.DB.realm.highestLevel = playerInfo.Level
        self.DB.realm.leader = { playerInfo.Name, playerInfo.Level, dingedAt }

        if playerInfo.Level == TheClassicRace.Config.MaxLevel then
            TheClassicRace:PPrint("The race is over! Gratz to " .. playerInfo.Name .. ", first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.Name) .. ", first to reach level " .. playerInfo.Level .. "!")
        end

        self:OnMaxLevelBump()
    elseif isDing then
        TheClassicRace:PPrint("Gratz to " .. playerInfo.Name .. ", reached level " .. playerInfo.Level .. "!")
    end
end