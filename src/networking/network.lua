-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local CreateFrame, GetChannelList, GetNumDisplayChannels = _G.CreateFrame, _G.GetChannelList, _G.GetNumDisplayChannels

-- Libs
local LibStub = _G.LibStub
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")
local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibCompress = LibStub:GetLibrary("LibCompress")
local EncodeTable = LibCompress:GetAddonEncodeTable()

--[[
TheClassicRaceNetwork uses AceComm to send and receive messages over Addon channels
and broadcast them as events once received fully over our EventBus.
--]]
---@class TheClassicRaceNetwork
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceNetwork = {}
TheClassicRaceNetwork.__index = TheClassicRaceNetwork
TheClassicRace.Network = TheClassicRaceNetwork

setmetatable(TheClassicRaceNetwork, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

---@param Core TheClassicRaceCore
---@param EventBus TheClassicRaceEventBus
function TheClassicRaceNetwork.new(Core, EventBus)
    local self = setmetatable({}, TheClassicRaceNetwork)

    self.Core = Core
    self.EventBus = EventBus
    self.MessageBuffer = {}

    -- create a Frame to use as thread to recieve events on
    self.Thread = CreateFrame("Frame")
    self.Thread:Hide()
    self.Thread:SetScript("OnEvent", function(_, event)
        TheClassicRace:DebugPrint(event)
        if (event == "CHANNEL_UI_UPDATE") then
            self:InitChannel()
        end
    end)

    -- init channel if we're not too early (otherwise we'll wait for CHANNEL_UI_UPDATE)
    if GetNumDisplayChannels() > 0 then
        self:InitChannel()
    end
    -- register for CHANNEL_UI_UPDATE so we know when our channel might have changed
    self.Thread:RegisterEvent("CHANNEL_UI_UPDATE")

    AceComm:RegisterComm(TheClassicRace.Config.Network.Prefix, function(...)
        self:HandleAddonMessage(...)
    end)

    return self
end

function TheClassicRaceNetwork:InitChannel()
    local channelId = nil
    local channels = { GetChannelList() }
    local i = 2
    while i < #channels do
        if (channels[i] == TheClassicRace.Config.Network.Channel.Name) then
            channelId = channels[i - 1]
            break
        end
        i = i + 3
    end

    TheClassicRace.Config.Network.Channel.Id = channelId
end

function TheClassicRaceNetwork:HandleAddonMessage(...)
    -- sender is always full name (name-realm)
    local prefix, message, _, sender = ...

    -- check if it's our prefix
    if prefix ~= TheClassicRace.Config.Network.Prefix then
        return
    end

    -- so we can pretend to be somebody else
    if sender == self.Core:FullRealMe() then
        sender = self.Core:FullMe()
    end

    -- ignore our own messages
    if sender == self.Core:FullRealMe() then
        return
    end

    -- completely ignore anything from other realms
    local _, senderRealm = self.Core:SplitFullPlayer(sender)
    if not self.Core:IsMyRealm(senderRealm) then
        return
    end

    local decoded = EncodeTable:Decode(message)
    local decompressed, _ = LibCompress:Decompress(decoded)

    local _, object = Serializer:Deserialize(decompressed)
    local event, payload = object[1], object[2]

    TheClassicRace:TracePrint("Received Network Event: " .. event .. " From: " .. sender)

    self.EventBus:PublishEvent(event, payload, sender)
end

function TheClassicRaceNetwork:SendObject(event, object, channel, target, prio)
    -- default to using the configured channel ID
    if channel == "CHANNEL" and target == nil then
        target = TheClassicRace.Config.Network.Channel.Id
    end
    -- no channel, no broadcast
    if channel == "CHANNEL" and target == nil then
        return
    end
    -- no priority, BULK
    if prio == nil then
        prio = "BULK"
    end

    local payload = Serializer:Serialize({event, object})
    local compressed = LibCompress:CompressHuffman(payload)
    local encoded = EncodeTable:Encode(compressed)

    TheClassicRace:TracePrint("Send Network Event: " .. event .. " Channel: " .. channel ..
            " Size: " .. string.len(encoded) .. " / " .. string.len(payload))

    AceComm:SendCommMessage(
            TheClassicRace.Config.Network.Prefix,
            encoded,
            channel,
            target,
            prio)
end
