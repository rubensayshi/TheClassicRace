--[[
Networking code from https://github.com/DomenikIrrgang/ClassicLFG released under MIT.
Copyright (c) 2019 Domenik Irrgang

TheClassicRaceNetwork will receive messages over Addon channels and broadcast them as events once received fully.
Objects sent are serialized and chunked to fit max size of messages.

@TODO: replace with AceComm-3.0
--]]
-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local CreateFrame, C_ChatInfo, GetChannelList, GetNumDisplayChannels =
_G.CreateFrame, _G.C_ChatInfo, _G.GetChannelList, _G.GetNumDisplayChannels

-- Libs
local LibStub = _G.LibStub
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")

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

    -- create a Frame to use as thread to recieve messages on
    self.NetworkThread = CreateFrame("Frame")
    self.NetworkThread:SetScript("OnUpdate", function()
        --print("Network Thread invoked!")
    end)
    self.NetworkThread:RegisterEvent("CHAT_MSG_ADDON")
    self.NetworkThread:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
    self.NetworkThread:SetScript("OnEvent", function(_, event, ...)
        TheClassicRace:DebugPrint(event)
        if (event == "CHANNEL_UI_UPDATE") then
            self.NetworkThread:UnregisterEvent("CHANNEL_UI_UPDATE")
            self:InitChannel()
        elseif (event == "CHAT_MSG_ADDON" or event == "CHAT_MSG_ADDON_LOGGED") then
            self:HandleAddonMessage(...)
        end
    end)

    -- init channel or register for a CHANNEL_UI_UPDATE if we're too early
    if GetNumDisplayChannels() > 0 then
        self:InitChannel()
    else
        self.NetworkThread:RegisterEvent("CHANNEL_UI_UPDATE")
    end

    -- register our prefix for addon messages
    C_ChatInfo.RegisterAddonMessagePrefix(TheClassicRace.Config.Network.Prefix)

    return self
end

function TheClassicRaceNetwork:InitChannel()
    local channels = { GetChannelList() }
    local i = 2
    while i < #channels do
        if (channels[i] == TheClassicRace.Config.Network.Channel.Name) then
            TheClassicRace.Config.Network.Channel.Id = channels[i - 1]
            break
        end
        i = i + 3
    end
end

function TheClassicRaceNetwork:HandleAddonMessage(...)
    -- sender is always full name (name-realm)
    local prefix, message, _, sender = ...

    -- so we can pretend to be somebody else
    if sender == self.Core:FullRealMe() then
        sender = self.Core:FullMe()
    end

    -- completely ignore anything from other realms
    local _, senderRealm = self.Core:SplitFullPlayer(sender)
    if not self.Core:IsMyRealm(senderRealm) then
        return
    end

    -- @TODO: does sender always include server?
    if (prefix:find(TheClassicRace.Config.Network.Prefix) and sender ~= self.Core:FullRealMe()) then
        local headers, content = self:SplitNetworkPackage(message)
        self.MessageBuffer[headers.Hash] = self.MessageBuffer[headers.Hash] or {}
        self.MessageBuffer[headers.Hash][headers.Order] = content

        -- manage count of chunks
        if (self.MessageBuffer[headers.Hash]["count"] ~= nil and self.MessageBuffer[headers.Hash]["count"] >= 1) then
            self.MessageBuffer[headers.Hash]["count"] = self.MessageBuffer[headers.Hash]["count"] + 1
        else
            self.MessageBuffer[headers.Hash]["count"] = 1
        end

        -- if this was the final chunk we can process it
        if (self.MessageBuffer[headers.Hash]["count"] == tonumber(headers.TotalCount)) then
            local _, object = Serializer:Deserialize(self:MergeMessages(headers, self.MessageBuffer[headers.Hash]))

            TheClassicRace:TracePrint("Network Package from " .. sender .. " complete! Event: " .. object.Event)

            self.MessageBuffer[headers.Hash] = nil
            self.EventBus:PublishEvent(object.Event, object.Payload, sender)
        end
    end
end

function TheClassicRaceNetwork:SendObject(event, object, channel, target)
    -- default to using the configured channel ID
    if channel == "CHANNEL" and target == nil then
        target = TheClassicRace.Config.Network.Channel.Id
    end
    -- no channel, no broadcast
    if channel == "CHANNEL" and target == nil then
        return
    end

    TheClassicRace:TracePrint("Network Event Send")
    TheClassicRace:TracePrint("Event: " .. event .. " Channel: " .. channel)
    self:SendMessage(TheClassicRace.Config.Network.Prefix, Serializer:Serialize({ Event = event, Payload = object }), channel, target)
end

function TheClassicRaceNetwork:SendMessage(prefix, message, channel, target)
    local messages = self:SplitMessage(message)
    for key in pairs(messages) do
        C_ChatInfo.SendAddonMessage(prefix, messages[key], channel, target)
    end
end

function TheClassicRaceNetwork:MergeMessages(headers, messages)
    local tmp = ""
    for i = 1, tonumber(headers.TotalCount) do
        tmp = tmp .. messages[tostring(i)]
    end
    return tmp
end

function TheClassicRaceNetwork:SplitMessage(message)
    local messages = {}
    local hash = self.RandomHash(8)
    -- Note: -3 for Splitting Characters in protocol and -2 for MessageCount and TotalCount and - hashlength
    local maxSize = 255 - 3 - 2 - hash:len()
    local totalCount = math.ceil(message:len() / maxSize)
    if (totalCount >= 10) then
        -- Note: -9 for Messages with Count < 10 and -2 for for increased Size of MessageCount and TotalCount
        totalCount = math.ceil((message:len() - 9) / (maxSize - 2))
    end
    local index = 1
    local messageCount = 1
    while (index < message:len()) do
        local headers = self:CreatePackageHeaders(messageCount, hash, totalCount)
        local content = message:sub(index, (index - 1) + 255 - headers.Length)
        table.insert(messages, self:CreateNetworkPackage(headers, content))
        index = index + content:len()
        messageCount = messageCount + 1
    end
    return messages
end

function TheClassicRaceNetwork:CreatePackageHeaders(messageCount, hash, totalCount)
    return { Order = messageCount, Hash = hash, TotalCount = totalCount, Length = 3 + hash:len() + tostring(messageCount):len() + tostring(totalCount):len() }
end

function TheClassicRaceNetwork:CreateNetworkPackage(headers, content)
    local header = headers.Hash .. "\a" .. headers.Order .. "\a" .. headers.TotalCount .. "\a"
    return header .. content
end

function TheClassicRaceNetwork:SplitNetworkPackage(package)
    local splitPackage = package:SplitString("\a")
    local headers = self:CreatePackageHeaders(splitPackage[2], splitPackage[1], splitPackage[3])
    local content = splitPackage[4]
    return headers, content
end

function TheClassicRaceNetwork.RandomHash(length)
    return TheClassicRace.RandomHash(length)
end
