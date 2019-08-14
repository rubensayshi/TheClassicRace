-- Libs
local LibStub = _G.LibStub

-- Addon global
local TheClassicRace = _G.TheClassicRace

-- deps
local AceGUI = LibStub("AceGUI-3.0")

-- WoW API
local GameFontNormalLarge, CLASS_ICON_TCOORDS = _G.GameFontNormalLarge, _G.CLASS_ICON_TCOORDS

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

    self.myClassIndex, self.myClass = self.Core:MyClass()

    -- subscribe to local events
    EventBus:RegisterCallback(self.Config.Events.Ding, self, self.OnDing)
    EventBus:RegisterCallback(self.Config.Events.RefreshGUI, self, self.OnRefreshGUI)

    self.classIndex = 0
    self.frame = nil
    self.tabicons = nil
    self.contentframe = nil

    self:OnRefreshGUI()

    return self
end

function TheClassicRaceStatusFrame:OnDing()
    self:Refresh()
end

function TheClassicRaceStatusFrame:OnRefreshGUI()
    self:Refresh()
end

function TheClassicRaceStatusFrame:Refresh()
    self.players = self.DB.factionrealm.leaderboard[self.classIndex].players

    if self.frame ~= nil and self.contentframe ~= nil then
        self:RenderTabicons()
        self:Render()
    end
end

function TheClassicRaceStatusFrame:Show()
    -- close currently open frame
    if self.frame then
        self.frame:Hide()
    end

    local _self = self

    -- toggle display state in DB
    self.DB.profile.gui.display = true

    local frame = AceGUI:Create("Window")
    -- bind status to DB, default width/height in defaultdb schema
    frame:SetStatusTable(self.DB.profile.gui.statusFrameStatus)
    frame:SetTitle("The Classic Race")
    frame.frame:SetFrameStrata("LOW")
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        -- toggle display state in DB
        _self.DB.profile.gui.display = false

        -- release self
        widget:Release()
        _self.frame = nil

        -- release tabicons
        if _self.tabicons then
            _self.tabicons:Release()
            _self.tabicons = nil
        end
    end)
    TheClassicRaceStatusFrame.FixResizeStatusUpdates(frame)
    frame:DoLayout()

    self.frame = frame

    self:RenderTabicons()
    self:Render()
end

--[[
FixResizeStatusUpdates fixes a bug in AceGUI
The OnMouseUp of the sizers don't update the status, so we add a new OnMouseUp that does
--]]
function TheClassicRaceStatusFrame.FixResizeStatusUpdates(frame)
    for _, sizer in ipairs({ frame.sizer_se, frame.sizer_s, frame.sizer_e }) do
        sizer:SetScript("OnMouseUp", function()
            frame.frame:StopMovingOrSizing()
            local status = frame.status or frame.localstatus
            status.width = frame.frame:GetWidth()
            status.height = frame.frame:GetHeight()
            status.top = frame.frame:GetTop()
            status.left = frame.frame:GetLeft()
        end)
    end
end

function TheClassicRaceStatusFrame:RenderTabicons()
    -- close currently open frame
    if self.tabicons then
        self.tabicons:Release()
    end

    local tabicons = AceGUI:Create("SimpleGroup")
    tabicons.frame:SetFrameStrata("LOW")
    tabicons:SetLayout("Flow")
    tabicons:SetWidth(20)
    tabicons:SetHeight(120)
    tabicons:SetFullWidth(false)
    tabicons.frame:Show()

    -- global
    local globalIcon = AceGUI:Create("Icon")
    globalIcon:SetCallback("OnClick", function()
        self.classIndex = 0
        self:Refresh()
    end)
    globalIcon:SetLabel(nil)
    globalIcon:SetImage("Interface\\PaperDollInfoFrame\\SpellSchoolIcon7")
    globalIcon:SetImageSize(20, 20)
    globalIcon:SetWidth(20)
    globalIcon:SetHeight(20)
    if self.classIndex ~= 0 then
        globalIcon.image:SetVertexColor(0.8, 0.8, 0.8, 0.8)
    end
    tabicons:AddChild(globalIcon)

    -- own class
    local coords = CLASS_ICON_TCOORDS[self.myClass]
    local classIcon = AceGUI:Create("Icon")
    classIcon:SetCallback("OnClick", function()
        self.classIndex = self.myClassIndex
        self:Refresh()
    end)
    classIcon:SetLabel(nil)
    classIcon:SetImage("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES", unpack(coords))
    classIcon:SetImageSize(20, 20)
    classIcon:SetWidth(20)
    classIcon:SetHeight(20)
    if self.classIndex ~= self.myClassIndex then
        classIcon.image:SetVertexColor(0.8, 0.8, 0.8, 0.8)
    end
    tabicons:AddChild(classIcon)

    -- attach to the edge of the main frame
    tabicons:ClearAllPoints()
    tabicons.frame:SetPoint("TOPLEFT", self.frame.frame, "TOPRIGHT")
    tabicons.frame:Show()

    self.tabicons = tabicons
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
    if #self.players > 0 then
        local leader = self.players[1]

        -- determine your own rank
        local selfRank = nil
        for rank, playerInfo in ipairs(self.players) do
            if playerInfo.name == self.Core:Me() then
                selfRank = rank
                break
            end
        end

        -- special leader display when you are the leader!
        if selfRank ~= nil and selfRank == 1 then
            local leaderLabel = AceGUI:Create("Label")
            leaderLabel:SetFullWidth(true)
            leaderLabel:SetText(SEYELLOW .. "You|r are #1! lvl" .. leader.level)
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
            leaderLabel:SetText("#1 " .. color .. leader.name .. "|r lvl" .. leader.level)
            leaderLabel:SetFont(GameFontNormalLarge:GetFont())
            leaderLabel.label:SetJustifyH("CENTER")
            frame:AddChild(leaderLabel)
        end

        -- special added line if you are on the leaderboard but not the leader
        if selfRank ~= nil and selfRank > 1 then
            local you = AceGUI:Create("Label")
            you:SetFullWidth(true)
            you:SetText("You are #" .. selfRank .. "! lvl" .. self.players[selfRank].level)
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

    for rank, playerInfo in ipairs(self.players) do
        if rank ~= 1 then
            local playerClass = self.Core:ClassByIndex(playerInfo.classIndex)
            local color = TheClassicRace.Colors[playerClass]
            if color == nil then
                color = WHITE
            end

            local player = AceGUI:Create("Label")
            player:SetText("#" .. rank .. " " .. color .. playerInfo.name .. "|r lvl" .. playerInfo.level)

            scroll:AddChild(player)
        end
    end

    -- trigger layout update to fix blank first row
    scroll:DoLayout()

    self.contentframe = frame
end