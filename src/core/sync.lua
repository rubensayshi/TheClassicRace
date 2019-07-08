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

    self.classIndex = self.Core:MyClass()

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
    self.Network:SendObject(self.Config.Network.Events.RequestSync, self.classIndex, "CHANNEL")
    if IsInGuild() then
        self.Network:SendObject(self.Config.Network.Events.RequestSync, self.classIndex, "GUILD")
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

    -- offer to the requester to sync with him
    self.Network:SendObject(self.Config.Network.Events.OfferSync, { self.classIndex, self.lastSync }, "WHISPER", sender)
end

function TheClassicRaceSync:OnNetOfferSync(offer, sender)
    local classIndex, lastSync = offer[1], offer[2]
    TheClassicRace:DebugPrint("OnNetOfferSync(" .. sender .. ")")
    -- add anyone who offers to sync with us
    table.insert(self.offers, {name = sender, classIndex = classIndex, lastSync = lastSync})
end

function TheClassicRaceSync:SelectPartner()
    -- we prefer to sync with same class without violating their throttle
    -- otherwise same class, but violate their throttle
    -- otherwise any class without violating their throttle
    -- otherwise any class, but voilate their throttle
    local now = self.Core:Now()
    local classIndex = self.classIndex
    local OfferSyncThrottle = self.Config.OfferSyncThrottle

    local offerModes = {"SAME_CLASS_THROTTLED", "SAME_CLASS", "THROTTLED", "ALL"}
    for _, offerMode in ipairs(offerModes) do
        local offers
        if offerMode == "SAME_CLASS_THROTTLED" then
            offers = TheClassicRace.list.filter(self.offers, function(offer)
                return offer.classIndex == classIndex and
                        (offer.lastSync == nil or offer.lastSync < now - OfferSyncThrottle)
            end)
        elseif offerMode == "SAME_CLASS" then
            offers = TheClassicRace.list.filter(self.offers, function(offer)
                return offer.classIndex == classIndex
            end)
        elseif offerMode == "THROTTLED" then
            offers = TheClassicRace.list.filter(self.offers, function(offer)
                return offer.lastSync == nil or offer.lastSync < now - OfferSyncThrottle
            end)
        else
            offers = self.offers
        end

        if #offers > 0 then
            return self:SelectPartnerFromList(offers)
        end
    end
end

function TheClassicRaceSync:SelectPartnerFromList(offers)
    -- select random offer
    local index = math.random(1, #offers)
    return table.remove(offers, index)
end

function TheClassicRaceSync:DoSync()
    -- no offers
    if #self.offers == 0 then
        TheClassicRace:DebugPrint("no sync partners")

        -- mark ourselves as synced up, otherwise nobody can ever sync
        self.isReady = true
        return
    end

    -- select a partner to sync with
    self.syncPartner = self:SelectPartner()

    -- remove the partner from the list of offers (in case we want to retry with another partner)
    self.offers = TheClassicRace.list.filter(self.offers, function(offer)
        return offer.name ~= self.syncPartner.name
    end)

    TheClassicRace:DebugPrint("DoSync(" .. self.syncPartner.name .. ")")

    -- request the actual start of the sync
    self.Network:SendObject(self.Config.Network.Events.StartSync, self.classIndex, "WHISPER", self.syncPartner.name)

    -- check if we need to retry syncing after a short timeout
    local _self = self
    C_Timer.After(self.Config.RetrySyncWait, function()
        if not self.isReady then
            _self:DoSync()
        end
    end)

    -- sync our data to our sync partner, he can then broadcast anything note worthy to the rest
    -- sync our global leaderboard
    self:Sync(self.syncPartner.name, 0)
    -- sync our class leaderboard if our sync partner is of the same class
    if self.syncPartner.classIndex == self.classIndex then
        self:Sync(self.syncPartner.name, self.classIndex)
    end
end

function TheClassicRaceSync:Sync(syncTo, classIndex)
    local batchstr = TheClassicRace.Serializer.SerializePlayerInfoBatch(self.DB.factionrealm.leaderboard[classIndex].players)

    self.Network:SendObject(self.Config.Network.Events.SyncPayload, batchstr, "WHISPER", syncTo)
end

function TheClassicRaceSync:OnNetStartSync(_, sender, classIndex)
    TheClassicRace:DebugPrint("OnNetStartSync(" .. sender .. ")")

    -- mark last sync
    self.lastSync = self.Core:Now()

    -- sync data to requester
    -- sync our global leaderboard
    self:Sync(sender, 0)
    -- sync our class leaderboard if our sync partner is of the same class
    if classIndex == self.classIndex then
        self:Sync(sender, self.classIndex)
    end
end

function TheClassicRaceSync:OnNetSyncPayload(payload, sender)
    TheClassicRace:DebugPrint("OnNetSyncPayload(" .. sender .. ")")

    -- if we've requested sync data then we shouldn't broadcast what we receive because it should already have been spread
    -- if we're provided sync data then we should broadcast relevant info
    local shouldBroadcast = self.isReady

    local batch = TheClassicRace.Serializer.DeserializePlayerInfoBatch(payload)

    -- push into our eventbus
    self.EventBus:PublishEvent(self.Config.Events.SyncResult, batch, shouldBroadcast)

    -- mark ourselves as synced up
    if not self.isReady then
        TheClassicRace:DebugPrint("we're now synced up")
        self.isReady = true
    end
end

