-- Libs
local LibStub = _G.LibStub

-- Addon global
---@class TheClassicRace
---@field Config TheClassicRaceConfig
---@field Colors TheClassicRaceColors
---@field Core TheClassicRaceCore
---@field Network TheClassicRaceNetwork
---@field EventBus TheClassicRaceEventBus
---@field Updater TheClassicRaceUpdater
---@field Tracker TheClassicRaceTracker
---@field ChatNotifier TheClassicRaceChatNotifier
---@field StatusFrame TheClassicRaceStatusFrame
---@field DefaultDB TheClassicRaceDefaultDB
TheClassicRace = LibStub("AceAddon-3.0"):NewAddon("TheClassicRace", "AceConsole-3.0")

function TheClassicRace:OnInitialize()
    self.DB = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)

    -- @TODO: these are related to the stuff in dev.lua...
    self:RegisterChatCommand("tcr", "tcr")

    -- determine who we are
    local player, realm = UnitFullName("player")

    -- init components (should have minimal side effects)
    self.Core = TheClassicRace.Core(player, realm)
    self.EventBus = TheClassicRace.EventBus()
    self.Network = TheClassicRace.Network(self.Core, self.EventBus)
    self.Updater = TheClassicRace.Updater(self.Core, self.DB, self.EventBus, who)
    self.Tracker = TheClassicRace.Tracker(TheClassicRace.Config, self.Core, self.DB, self.EventBus, self.Network)
    self.ChatNotifier = TheClassicRace.ChatNotifier(TheClassicRace.Config, self.Core, self.EventBus)
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
