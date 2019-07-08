-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local CreateFrame = _G.CreateFrame

--[[
Updater is responsible for when we level up ourselves
]]--
---@class TheClassicRaceUpdater
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceUpdater = {}
TheClassicRaceUpdater.__index = TheClassicRaceUpdater
TheClassicRace.Updater = TheClassicRaceUpdater
setmetatable(TheClassicRaceUpdater, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceUpdater.new(Core, EventBus)
    local self = setmetatable({}, TheClassicRaceUpdater)

    self.Core = Core
    self.EventBus = EventBus

    -- create a Frame to use as thread to receive events on
    self.Thread = CreateFrame("Frame")
    self.Thread:Hide()
    self.Thread:SetScript("OnEvent", function(_, event, ...)
        if (event == "PLAYER_LEVEL_UP") then
            self:OnPlayerLevelUp(...)
        end
    end)

    -- register for level up events
    self.Thread:RegisterEvent("PLAYER_LEVEL_UP")

    return self
end

function TheClassicRaceUpdater:OnPlayerLevelUp(level)
    TheClassicRace:DebugPrint("OnPlayerLevelUp(" .. tostring(level) .. ")")

    local classIndex = self.Core:MyClass()

    -- we fake an /who result
    self.EventBus:PublishEvent(TheClassicRace.Config.Events.SlashWhoResult, {{
        name = self.Core:Me(),
        level = level,
        classIndex = classIndex,
    }, })
end
