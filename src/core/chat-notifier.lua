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

function TheClassicRaceChatNotifier.new(Config, Core, DB, EventBus)
    local self = setmetatable({}, TheClassicRaceChatNotifier)

    self.Config = Config
    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus

    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(self.Config.Events.RaceFinished, self, self.OnRaceFinished)

    return self
end

function TheClassicRaceChatNotifier:OnDing(playerInfo, rank)
    if not self.DB.profile.options.notifications then
        return
    end

    -- for any old dings except the rank 1 we ignore
    if rank > 1 and playerInfo.dingedAt < self.Core:Now() - 600 then
        return
    end

    if playerInfo.name == self.Core:Me() then
        self:OnSelfDing(playerInfo, rank)
    else
        self:OnStrangerDing(playerInfo, rank)
    end
end

function TheClassicRaceChatNotifier:OnSelfDing(playerInfo, rank)
    local chatLink = TheClassicRace:PlayerChatLink(playerInfo.name, "You", self.Core:ClassByIndex(playerInfo.classIndex))

    if rank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz! The race is over! " .. chatLink .. " are the first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz! " .. chatLink .. " are first to reach level " .. playerInfo.level .. "!")
        end
    else
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz!  " .. chatLink .. " reached max level as #" .. rank .. "!")
        else
            TheClassicRace:PPrint("Gratz! " .. chatLink .. " reached level " .. playerInfo.level .. "! " ..
                    "Currently rank #" .. rank .. " in the race!")
        end
    end
end

function TheClassicRaceChatNotifier:OnStrangerDing(playerInfo, rank)
    local chatLink = TheClassicRace:PlayerChatLink(playerInfo.name, nil, self.Core:ClassByIndex(playerInfo.classIndex))

    if rank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("The race is over! Gratz to " .. chatLink .. ", first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz to " .. chatLink .. ", " ..
                    "first to reach level " .. playerInfo.level .. "!")
        end
    else
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz to " .. chatLink .. ", reached max level as #" .. rank .. "!")
        else
            TheClassicRace:PPrint("Gratz to " .. chatLink .. ", reached level " .. playerInfo.level .. "! " ..
                    "Currently rank #" .. rank .. " in the race!")
        end
    end
end

function TheClassicRaceChatNotifier:OnRaceFinished()
    TheClassicRace:PPrint("More than " .. self.DB.profile.options.leaderboardSize .. " players have reached max level, the race is over!")
end
