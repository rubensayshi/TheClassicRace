-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
ChatNotifier is responsible for notifying the user about events through the chat window
based on events from the EventBus
]]--
---@class TheClassicRaceChatNotifier
---@field Config TheClassicRaceConfig
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceChatNotifier = {}
TheClassicRaceChatNotifier.__index = TheClassicRaceChatNotifier
TheClassicRace.ChatNotifier = TheClassicRaceChatNotifier
setmetatable(TheClassicRaceChatNotifier, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceChatNotifier.new(Config, Core, EventBus)
    local self = setmetatable({}, TheClassicRaceChatNotifier)

    self.Config = Config
    self.Core = Core
    self.EventBus = EventBus

    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(self.Config.Events.RaceFinished, self, self.OnRaceFinished)

    return self
end

function TheClassicRaceChatNotifier:OnDing(playerInfo, rank)
    if playerInfo.name == self.Core:Me() then
        self:OnSelfDing(playerInfo, rank)
    else
        self:OnStrangerDing(playerInfo, rank)
    end
end

function TheClassicRaceChatNotifier:OnSelfDing(playerInfo, rank)
    if rank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz! The race is over! " .. TheClassicRace:PlayerChatLink(playerInfo.name, "You") .. " are the first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz! " .. TheClassicRace:PlayerChatLink(playerInfo.name, "You") .. " are first to reach level " .. playerInfo.level .. "!")
        end
    else
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz!  " .. TheClassicRace:PlayerChatLink(playerInfo.name, "You") .. " reached max level as #" .. rank .. "!")
        else
            TheClassicRace:PPrint("Gratz! " .. TheClassicRace:PlayerChatLink(playerInfo.name, "You") .. " reached level " .. playerInfo.level .. "! " ..
                    "Currently rank #" .. rank .. " in the race!")
        end
    end
end

function TheClassicRaceChatNotifier:OnStrangerDing(playerInfo, rank)
    if rank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("The race is over! Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", " ..
                    "first to reach level " .. playerInfo.level .. "!")
        end
    else
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", reached max level as #" .. rank .. "!")
        else
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", reached level " .. playerInfo.level .. "! " ..
                    "Currently rank #" .. rank .. " in the race!")
        end
    end
end

function TheClassicRaceChatNotifier:OnRaceFinished()
    TheClassicRace:PPrint("More than " .. self.Config.LeaderboardSize .. " players have reached max level, the race is over!")
end
