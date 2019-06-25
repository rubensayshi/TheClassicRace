-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
ChatNotifier is responsible for notifying the user about events through the chat window
based on events from the EventBus
]]--
---@class TheClassicRaceChatNotifier
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

    return self
end

function TheClassicRaceChatNotifier:OnDing(playerInfo, rank)
    if rank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("The race is over! Gratz to " .. playerInfo.name .. ", first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz to " .. TheClassicRace:PlayerChatLink(playerInfo.name) .. ", " ..
                    "first to reach level " .. playerInfo.level .. "!")
        end
    else
        TheClassicRace:PPrint("Gratz to " .. playerInfo.name .. ", reached level " .. playerInfo.level .. "! " ..
                "Currently rank #" .. rank .. " in the race!")
    end
end
