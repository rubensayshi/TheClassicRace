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

function TheClassicRaceChatNotifier:OnDing(playerInfo, globalRank, classRank)
    -- check if we should report on this ding
    if not self:ShouldReport(playerInfo, globalRank, classRank) then
        return
    end

    if playerInfo.name == self.Core:Me() then
        self:OnSelfDing(playerInfo, globalRank, classRank)
    else
        self:OnStrangerDing(playerInfo, globalRank, classRank)
    end
end


function TheClassicRaceChatNotifier:ShouldReport(playerInfo, globalRank, classRank)
    -- any old dings except rank 1 we ignore
    if playerInfo.dingedAt < self.Core:Now() - 600
            and (globalRank == nil or globalRank > 1)
            and (classRank == nil or classRank > 1) then
        return false
    end

    if playerInfo.classIndex ~= self.Core:MyClass() then
        if not self.DB.profile.options.globalNotifications then
            return false
        end

        -- no notifications for globalRanks below threshold of other classes
        if globalRank == nil or globalRank > self.DB.profile.options.globalNotificationThreshold then
            return false
        end
    else
        if not self.DB.profile.options.classNotifications then
            return false
        end

        -- no notifications for class ranks below threshold
        if classRank == nil or classRank > self.DB.profile.options.classNotificationThreshold then
            return false
        end
    end

    return true
end

function TheClassicRaceChatNotifier:OnSelfDing(playerInfo, globalRank, classRank)
    self:DingNotification(playerInfo, globalRank, classRank, true)
end

function TheClassicRaceChatNotifier:OnStrangerDing(playerInfo, globalRank, classRank)
    self:DingNotification(playerInfo, globalRank, classRank, false)
end

function TheClassicRaceChatNotifier:DingNotification(playerInfo, globalRank, classRank, isSelf)
    local className = self.Core:ClassByIndex(playerInfo.classIndex)
    local prettyClassName = self.Config.PrettyClassNames[className]
    local chatLink
    local addressPerson
    if isSelf then
        chatLink = TheClassicRace:PlayerChatLink(playerInfo.name, "You", className)
        addressPerson = chatLink .. " are"
    else
        chatLink = TheClassicRace:PlayerChatLink(playerInfo.name, nil, className)
        addressPerson = chatLink .. " is"
    end

    if globalRank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz! The race is over! " .. addressPerson .. " the first to reach max level!!")
        else
            TheClassicRace:PPrint("Gratz! " .. addressPerson .. " first to reach level " .. playerInfo.level .. "!")
        end
    elseif classRank == 1 and globalRank ~= nil then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz! The race is over! " .. addressPerson .. " the first to reach max level of all " ..
                    prettyClassName .. ", and #" .. globalRank .. " for all classes!!")
        else
            TheClassicRace:PPrint("Gratz! " .. addressPerson .. " first to reach level " .. playerInfo.level .. " of all " ..
                    prettyClassName .. ", and #" .. globalRank .. " for all classes!")
        end
    elseif classRank == 1 then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz! The race is over! " .. addressPerson .. " the first to reach max level of all " ..
                    prettyClassName .. "!! (not in top " .. self.Config.MaxLeaderboardSize .. " for all classes)")
        else
            TheClassicRace:PPrint("Gratz! " .. addressPerson .. " first to reach level " .. playerInfo.level .. " of all " ..
                    prettyClassName .. "!! (not in top " .. self.Config.MaxLeaderboardSize .. " for all classes)")
        end
    elseif globalRank ~= nil then
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz!  " .. chatLink .. " reached max level as #" .. classRank .. " of all " .. prettyClassName .. ", " ..
                    "and #" .. globalRank .. " for all classes!!")
        else
            TheClassicRace:PPrint("Gratz! " .. chatLink .. " reached level " .. playerInfo.level .. "! " ..
                    "Currently rank #" .. classRank .. " of all " .. prettyClassName .. " and #" .. globalRank .. " for all classes in the race!")
        end
    else
        if playerInfo.level == self.Config.MaxLevel then
            TheClassicRace:PPrint("Gratz!  " .. chatLink .. " reached max level as #" .. classRank .. " of all " .. prettyClassName .. "!" ..
                    " (not in top " .. self.Config.MaxLeaderboardSize .. " for all classes)")
        else
            TheClassicRace:PPrint("Gratz! " .. chatLink .. " reached level " .. playerInfo.level .. " as #" .. classRank
                    .. " of all " .. prettyClassName .. "! (not in top " .. self.Config.MaxLeaderboardSize .. " for all classes)")
        end
    end
end

function TheClassicRaceChatNotifier:OnRaceFinished()
    TheClassicRace:PPrint("More than " .. self.Config.MaxLeaderboardSize .. " players have reached max level, the race is over!")
end
