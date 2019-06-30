-- Libs
local LibStub = _G.LibStub

-- Addon global
---@class TheClassicRace
---@field Config        TheClassicRaceConfig
---       our config table
---@field Colors        TheClassicRaceColors
---       our color shorthand table
---@field Core          TheClassicRaceCore
---       contains basic helpers such as :Me(), :Now(), etc
---@field EventBus      TheClassicRaceEventBus
---       event bus to facilitate communication between components
---@field Network       TheClassicRaceNetwork
---       bridge between AceComms and our EventBus
---@field Updater       TheClassicRaceUpdater
---       contains ticker to start Scans and publishes events based of Scan results
---@field Tracker       TheClassicRaceTracker
---       manages the leaderboard based on events
---@field ChatNotifier  TheClassicRaceChatNotifier
---       writes notifications in chat window based on events
---@field StatusFrame   TheClassicRaceStatusFrame
---       GUI element to display the leaderboard
---@field DefaultDB     TheClassicRaceDefaultDB
TheClassicRace = LibStub("AceAddon-3.0"):NewAddon("TheClassicRace", "AceConsole-3.0")

function TheClassicRace:OnInitialize()
    self.DB = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)

    self:RegisterOptions()
    self:RegisterChatCommand("tcr", "slashtcr")

    -- determine who we are
    local player, realm = UnitFullName("player")

    -- init components (should have minimal side effects)
    self.Core = TheClassicRace.Core(player, realm)
    self.EventBus = TheClassicRace.EventBus()
    self.Network = TheClassicRace.Network(self.Core, self.EventBus)
    self.Updater = TheClassicRace.Updater(self.Core, self.DB, self.EventBus, who)
    self.Tracker = TheClassicRace.Tracker(TheClassicRace.Config, self.Core, self.DB, self.EventBus, self.Network)
    self.ChatNotifier = TheClassicRace.ChatNotifier(TheClassicRace.Config, self.Core, self.DB, self.EventBus)
    self.StatusFrame = TheClassicRace.StatusFrame(TheClassicRace.Config, self.Core, self.DB, self.EventBus)

    self:DebugPrint("me: " .. self.Core:RealMe())
end

function TheClassicRace:OnEnable()
    -- debug print, will also help us know if debugging is enabled
    self:DebugPrint("TheClassicRace:OnEnable")

    -- determine who we are
    local player, realm = UnitFullName("player")
    self.Core:InitMe(player, realm)
    self:DebugPrint("me: " .. self.Core:RealMe())

    -- request an update of data
    self.Tracker:RequestUpdate()

    -- start updater
    self.Updater:InitTicker()
    self.Updater:StartScan()
end

--[[
The /tcr handler, toggles the frame, unless overwritten in dev.lua with a more advanced development mode /tcr
--]]
function TheClassicRace:slashtcr(input)
    self.StatusFrame:Show()
end
