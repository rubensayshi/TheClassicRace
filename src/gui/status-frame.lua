-- Libs
local LibStub = _G.LibStub

-- Addon global
local TheClassicRace = _G.TheClassicRace

-- deps
local AceGUI = LibStub("AceGUI-3.0")

-- WoW API
local GameFontNormalLarge = _G.GameFontNormalLarge

-- colors
local SEYELLOW = TheClassicRace.Colors.SYSTEM_EVENT_YELLOW
local WHITE = TheClassicRace.Colors.WHITE

---@class TheClassicRaceStatusFrame
local TheClassicRaceStatusFrame = {}
TheClassicRaceStatusFrame.__index = TheClassicRaceStatusFrame
TheClassicRace.StatusFrame = TheClassicRaceStatusFrame
setmetatable(TheClassicRaceStatusFrame, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceStatusFrame.new(Config, Core, DB, EventBus)
    local self = setmetatable({}, TheClassicRaceStatusFrame)

    self.Config = Config
    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus

    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(self.Config.Events.RefreshGUI, self, self.OnRefreshGUI)

    self.frame = nil
    self.contentframe = nil

    return self
end

function TheClassicRaceStatusFrame:OnDing()
    self:Refresh()
end

function TheClassicRaceStatusFrame:OnRefreshGUI()
    self:Refresh()
end

function TheClassicRaceStatusFrame:Refresh()
    if self.frame ~= nil and self.contentframe ~= nil then
        self:Render()
    end
end

function TheClassicRaceStatusFrame:Show()
    -- close currently open frame
    if self.frame then
        self.frame:Hide()
    end

    local _self = self

    local frame = AceGUI:Create("Window")
    frame:SetTitle("The Classic Race")
    frame:SetWidth(200)
    frame:SetHeight(120)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        _self.frame = nil
    end)

    self.frame = frame

    self:Render()
end

function TheClassicRaceStatusFrame:Render()
    -- clear the old content
    self.frame:ReleaseChildren()

    local _self = self

    -- need a container
    local frame = AceGUI:Create("SimpleGroup")
    frame:SetLayout("Flow")
    frame:SetFullWidth(true)
    frame:SetFullHeight(true)
    frame:SetCallback("OnClose", function(widget)
        widget:ReleaseChildren()
        widget:Release()
        _self.contentframe = nil
    end)
    self.frame:AddChild(frame)

    -- display the leader
    if #self.DB.factionrealm.leaderboard > 0 then
        local leader = self.DB.factionrealm.leaderboard[1]

        -- determine your own rank
        local selfRank = nil
        for rank, playerInfo in ipairs(self.DB.factionrealm.leaderboard) do
            if playerInfo.name == self.Core:Me() then
                selfRank = rank
                break
            end
        end

        -- special leader display when you are the leader!
        if selfRank ~= nil and selfRank == 1 then
            local leaderLabel = AceGUI:Create("Label")
            leaderLabel:SetFullWidth(true)
            leaderLabel:SetText(SEYELLOW .. "You" .. WHITE .. " are #1!" .. WHITE .. " lvl" .. leader.level)
            leaderLabel:SetFont(GameFontNormalLarge:GetFont())
            leaderLabel.label:SetJustifyH("CENTER")
            frame:AddChild(leaderLabel)
        else
            local leaderClass = self.Core:ClassByIndex(leader.classIndex)
            local color = TheClassicRace.Colors[leaderClass]
            if color == nil then
                color = WHITE
            end

            local leaderLabel = AceGUI:Create("Label")
            leaderLabel:SetFullWidth(true)
            leaderLabel:SetText(WHITE .. "#1 " .. color .. leader.name .. WHITE .. " lvl" .. leader.level)
            leaderLabel:SetFont(GameFontNormalLarge:GetFont())
            leaderLabel.label:SetJustifyH("CENTER")
            frame:AddChild(leaderLabel)
        end

        -- special added line if you are on the leaderboard but not the leader
        if selfRank ~= nil and selfRank > 1 then
            local you = AceGUI:Create("Label")
            you:SetFullWidth(true)
            you:SetText(WHITE .. "You are #" .. selfRank .. "!" .. WHITE .. " lvl" .. self.DB.factionrealm.leaderboard[selfRank].level)
            you:SetFont(GameFontNormalLarge:GetFont())
            you.label:SetJustifyH("CENTER")
            frame:AddChild(you)
        end
    end

    local scrolltainer = AceGUI:Create("SimpleGroup")
    scrolltainer:SetLayout("Fill") -- important! first child fills container
    scrolltainer:SetFullWidth(true)
    scrolltainer:SetFullHeight(true)
    frame:AddChild(scrolltainer)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scrolltainer:AddChild(scroll)

    for rank, playerInfo in ipairs(self.DB.factionrealm.leaderboard) do
        if rank ~= 1 then
            local playerClass = self.Core:ClassByIndex(playerInfo.classIndex)
            local color = TheClassicRace.Colors[playerClass]
            if color == nil then
                color = WHITE
            end

            local player = AceGUI:Create("Label")
            player:SetText(WHITE .. "#" .. rank .. " " .. color .. playerInfo.name .. WHITE .. " lvl" .. playerInfo.level)

            scroll:AddChild(player)
        end
    end

    -- trigger layout update to fix blank first row
    scroll:DoLayout()

    self.contentframe = frame
end