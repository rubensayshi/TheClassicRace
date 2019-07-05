-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local C_Timer, IsInGuild = _G.C_Timer, _G.IsInGuild

--[[
TheClassicRaceSync handles both requesting a sync when we login and responding to others who are request a sync
]]--
---@class TheClassicRaceSync
---@field Config TheClassicRaceConfig
---@field Core TheClassicRaceCore
---@field DB table<string, table>
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceSync = {}
TheClassicRaceSync.__index = TheClassicRaceSync
TheClassicRace.Sync = TheClassicRaceSync
setmetatable(TheClassicRaceSync, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceSync.new(Config, Core, DB, EventBus, Network)
    local self = setmetatable({}, TheClassicRaceSync)

    self.Config = Config
    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus
    self.Network = Network

    self.isReady = false
    self.offers = {}
    self.syncPartner = nil
    self.lastSync = nil

    EventBus:RegisterCallback(self.Config.Network.Events.RequestSync, self, self.OnNetRequestSync)
    EventBus:RegisterCallback(self.Config.Network.Events.OfferSync, self, self.OnNetOfferSync)
    EventBus:RegisterCallback(self.Config.Network.Events.StartSync, self, self.OnNetStartSync)
    EventBus:RegisterCallback(self.Config.Network.Events.SyncPayload, self, self.OnNetSyncPayload)

    return self
end

function TheClassicRaceSync:InitSync()
    -- don't request updates when we know the race has finished
    if self.DB.factionrealm.finished then
        return
    end
    -- don't request updates when we've disabled networking
    if not self.DB.profile.options.networking then
        return
    end

    -- request a sync
    self.Network:SendObject(self.Config.Network.Events.RequestSync, true, "CHANNEL")
    if IsInGuild() then
        self.Network:SendObject(self.Config.Network.Events.RequestSync, true, "GUILD")
    end

    -- after 5s we attempt to sync with somebody who offered
    local _self = self
    C_Timer.After(self.Config.RequestSyncWait, function() _self:DoSync() end)
end

function TheClassicRaceSync:OnNetRequestSync(_, sender)
    -- don't respond to requests when we've disabled networking
    if not self.DB.profile.options.networking then
        return
    end

    TheClassicRace:DebugPrint("OnNetRequestSync(" .. sender .. ") isReady=" .. tostring(self.isReady))
    -- if we're still in the process of syncing up ourselves then we shouldn't offer ourselves to sync with
    if not self.isReady then
        return
    end

    -- @TODO: should throttle how often we offer, maybe a timestamp when we'd be willing to sync again
    -- offer to the requester to sync with him
    self.Network:SendObject(self.Config.Network.Events.OfferSync, self.lastSync, "WHISPER", sender)
end

function TheClassicRaceSync:OnNetOfferSync(lastSync, sender)
    TheClassicRace:DebugPrint("OnNetOfferSync(" .. sender .. ")")
    -- add anyone who offers to sync with us
    table.insert(self.offers, {name = sender, lastSync = lastSync})
end

function TheClassicRaceSync:SelectPartner(offers)
    local index = math.random(1, #offers)
    return table.remove(offers, index).name
end

function TheClassicRaceSync:DoSync()
    -- no offers
    if #self.offers == 0 then
        TheClassicRace:DebugPrint("no sync partners")

        -- mark ourselves as synced up, otherwise nobody can ever sync
        self.isReady = true
        return
    end

    local now = self.Core:Now()
    local OfferSyncThrottle = self.Config.OfferSyncThrottle
    local preferredOffers = TheClassicRace.list.filter(self.offers, function(offer)
        return offer.lastSync == nil or offer.lastSync < now - OfferSyncThrottle
    end)

    if #preferredOffers > 0 then
        -- select from preferred offers
        self.syncPartner = self:SelectPartner(preferredOffers)
        -- also remove the partner from the list of offers
        self.offers = TheClassicRace.list.filter(self.offers, function(offer)
            return offer.name ~= self.syncPartner
        end)
    else
        -- randomly select and remove one of the offered sync partners
        self.syncPartner = self:SelectPartner(self.offers)
    end

    TheClassicRace:DebugPrint("DoSync(" .. self.syncPartner .. ")")

    -- request the actual start of the sync
    self.Network:SendObject(self.Config.Network.Events.StartSync, true, "WHISPER", self.syncPartner)

    -- check if we need to retry syncing after a short timeout
    local _self = self
    C_Timer.After(self.Config.RetrySyncWait, function()
        if not self.isReady then
            _self:DoSync()
        end
    end)

    -- sync our data to our sync partner, he can then broadcast anything note worthy to the rest
    self:Sync(self.syncPartner)
end

function TheClassicRaceSync:Sync(syncTo)
    -- @TODO: compress?
    local payload = {}
    for _, playerInfo in ipairs(self.DB.factionrealm.leaderboard) do
        table.insert(payload, { playerInfo.name, playerInfo.level, playerInfo.dingedAt, playerInfo.classIndex })
    end

    self.Network:SendObject(self.Config.Network.Events.SyncPayload, payload, "WHISPER", syncTo)
end

function TheClassicRaceSync:OnNetStartSync(_, sender)
    TheClassicRace:DebugPrint("OnNetStartSync(" .. sender .. ")")

    -- mark last sync
    self.lastSync = self.Core:Now()

    -- sync data to requester
    self:Sync(sender)
end

function TheClassicRaceSync:OnNetSyncPayload(payload, sender)
    TheClassicRace:DebugPrint("OnNetSyncPayload(" .. sender .. ")")

    -- if we've requested sync data then we shouldn't broadcast what we receive because it should already have been spread
    -- if we're provided sync data then we should broadcast relevant info
    local shouldBroadcast = self.isReady

    -- push into our eventbus as if it was info receive from a PlayerInfo network event
    for _, playerInfo in ipairs(payload) do
        self.EventBus:PublishEvent(self.Config.Network.Events.PlayerInfo, {playerInfo, }, sender, shouldBroadcast)
    end

    -- mark ourselves as synced up
    if not self.isReady then
        TheClassicRace:DebugPrint("we're now synced up")
        self.isReady = true
    end
end

