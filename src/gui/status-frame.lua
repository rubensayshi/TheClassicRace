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

function TheClassicRaceStatusFrame.new(Config, Core, DB)
    local self = setmetatable({}, TheClassicRaceStatusFrame)

    self.Config = Config
    self.Core = Core
    self.DB = DB

    self.frame = nil

    return self
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

    -- display the leader
    if #self.DB.realm.leaderboard > 0 then
        -- determine your own rank
        local selfRank = nil
        for rank, playerInfo in ipairs(self.DB.realm.leaderboard) do
            if playerInfo.name == self.Core:Me() then
                selfRank = rank
                break
            end
        end

        -- special leader display when you are the leader!
        if selfRank ~= nil and selfRank == 1 then
            local leader = AceGUI:Create("Label")
            leader:SetFullWidth(true)
            leader:SetText(WHITE .. "You are #1!" .. SEYELLOW .. " lvl" .. self.DB.realm.leaderboard[1].level)
            leader:SetFont(GameFontNormalLarge:GetFont())
            leader.label:SetJustifyH("CENTER")
            frame:AddChild(leader)
        else
            local leader = AceGUI:Create("Label")
            leader:SetFullWidth(true)
            leader:SetText(WHITE .. "#1 " .. self.DB.realm.leaderboard[1].name .. SEYELLOW .. " lvl" .. self.DB.realm.leaderboard[1].level)
            leader:SetFont(GameFontNormalLarge:GetFont())
            leader.label:SetJustifyH("CENTER")
            frame:AddChild(leader)
        end

        -- special added line if you are on the leaderboard but not the leader
        if selfRank ~= nil and selfRank > 1 then
            local you = AceGUI:Create("Label")
            you:SetFullWidth(true)
            you:SetText(WHITE .. "You are #" .. selfRank .. "! " .. SEYELLOW .. " lvl" .. self.DB.realm.leaderboard[selfRank].level)
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

    for rank, playerInfo in ipairs(self.DB.realm.leaderboard) do
        if rank ~= 1 then
            local player = AceGUI:Create("Label")
            player:SetText(WHITE .. "#" .. rank .. " " .. playerInfo.name .. SEYELLOW .. " lvl" .. playerInfo.level)

            scroll:AddChild(player)
        end
    end

    self.frame = frame
end