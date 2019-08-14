-- Libs
local LibStub = _G.LibStub

-- Addon global
---@class TheClassicRace
---@field Config        TheClassicRaceConfig
---       our config table
---@field Colors        TheClassicRaceColors
---       our color shorthand table
---@field Serializer    TheClassicRaceSerializer
---       our custom serializer
---@field Core          TheClassicRaceCore
---       contains basic helpers such as :Me(), :Now(), etc
---@field EventBus      TheClassicRaceEventBus
---       event bus to facilitate communication between components
---@field Network       TheClassicRaceNetwork
---       bridge between AceComms and our EventBus
---@field Scanner       TheClassicRaceScanner
---       contains ticker to start Scans and publishes events based of Scan results
---@field Tracker       TheClassicRaceTracker
---       manages the leaderboard based on events
---@field ChatNotifier  TheClassicRaceChatNotifier
---       writes notifications in chat window based on events
---@field updater       TheClassicRaceUpdater
---@field Sync          TheClassicRaceSync
---       handles syncing when coming online
---@field StatusFrame   TheClassicRaceStatusFrame
---       GUI element to display the leaderboard
---@field DefaultDB     TheClassicRaceDefaultDB
TheClassicRace = LibStub("AceAddon-3.0"):NewAddon("TheClassicRace", "AceConsole-3.0")

function TheClassicRace:OnInitialize()
    self.Config = TheClassicRace.Config
    self.Colors = TheClassicRace.Colors
    self.DB = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)

    self:DBMigrations()

    -- determine who we are
    local player, realm = UnitFullName("player")

    -- init components (should have minimal side effects)
    self.Core = TheClassicRace.Core(self.Config, player, realm)
    self.EventBus = TheClassicRace.EventBus()
    self.Network = TheClassicRace.Network(self.Core, self.EventBus)
    self.Tracker = TheClassicRace.Tracker(self.Config, self.Core, self.DB, self.EventBus, self.Network)
    self.ChatNotifier = TheClassicRace.ChatNotifier(self.Config, self.Core, self.DB, self.EventBus)
    self.Sync = TheClassicRace.Sync(self.Config, self.Core, self.DB, self.EventBus, self.Network)
    self.updater = TheClassicRace.Updater(self.Core, self.EventBus)
    self.StatusFrame = TheClassicRace.StatusFrame(self.Config, self.Core, self.DB, self.EventBus)

    -- init a global scanner and a class specific scanner
    self.scanner = TheClassicRace.Scanner(self.Core, self.DB, self.EventBus)
    self.classScanner = TheClassicRace.Scanner(self.Core, self.DB, self.EventBus, self.Core:MyClass())

    self.EventBus:RegisterCallback(self.Config.Events.NetworkReady, self, function()
        self.Sync:InitSync()
    end)

    self:DebugPrint("me: " .. self.Core:RealMe())
end

function TheClassicRace:OnEnable()
    -- debug print, will also help us know if debugging is enabled
    self:DebugPrint("TheClassicRace:OnEnable")

    self:RegisterOptions()
    self:RegisterChatCommand("tcr", "slashtcr")

    -- determine who we are
    local player, realm = UnitFullName("player")
    self.Core:InitMe(player, realm)
    self:DebugPrint("me: " .. self.Core:RealMe())

    self.Network:Init()

    -- init the scanner ticker, first scan will happen when the ticker ticks
    self.scanner:InitTicker()
    self.classScanner:InitTicker(20)

    if self.DB.profile.gui.display then
        self.StatusFrame:Show()
    end
end

function TheClassicRace:DBMigrations()
    -- fresh DB or pre-versioning DB, reset and init ...
    if self.DB.factionrealm.dbversion == "0.0.0" then
        self:ResetDB()
    end
end

function TheClassicRace:ResetDB()
    self.DB:ResetDB()
    self.DB.factionrealm.dbversion = self.Config.Version
end

--[[
The /tcr handler, toggles the frame, unless overwritten in dev.lua with a more advanced development mode /tcr
--]]
function TheClassicRace:slashtcr(input)
    self.StatusFrame:Show()
end
