-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local GetServerTime, UnitClass = _G.GetServerTime, _G.UnitClass

---@class TheClassicRaceCore
---@field Config TheClassicRaceConfig
local TheClassicRaceCore = {}
TheClassicRaceCore.__index = TheClassicRaceCore
TheClassicRace.Core = TheClassicRaceCore

setmetatable(TheClassicRaceCore, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceCore.new(Config, player, realm)
    local self = setmetatable({}, TheClassicRaceCore)

    self.Config = Config

    self.InitMe(self, player, realm)

    return self
end

function TheClassicRaceCore:InitMe(player, realm)
    TheClassicRace:DebugPrint("InitMe: " .. tostring(player)  .. ", " .. tostring(realm))
    if realm == nil then
        realm = "NaN"
    end

    self.realm = realm
    self.realme = player
    self.me = self.realme
end

function TheClassicRaceCore:PlayerFull(player, realm)
    if realm == nil then
        realm = self.realm
    end

    return player .. "-" .. realm
end

function TheClassicRaceCore:IsMyRealm(realm)
    return realm == nil or realm == self.realm
end

function TheClassicRaceCore:MyRealm()
    return self.realm
end

function TheClassicRaceCore:Me()
    return self.me
end

function TheClassicRaceCore:RealMe()
    return self.realme
end

function TheClassicRaceCore:FullMe()
    return self:PlayerFull(self.me)
end

function TheClassicRaceCore:FullRealMe()
    return self:PlayerFull(self.realme)
end

function TheClassicRaceCore:MyClass()
    local _, className, _ = UnitClass("player")
    return className
end

function TheClassicRaceCore:ClassIndex(className)
    className = string.upper(className)
    className = string.gsub(className, " ", "")
    if self.Config.ClassIndexes[className] ~= nil then
        return self.Config.ClassIndexes[className]
    else
        return self.Config.UnknownClassIndex
    end
end

function TheClassicRaceCore:ClassByIndex(classIndex)
    if classIndex ~= nil and self.Config.Classes[classIndex] ~= nil then
        return self.Config.Classes[classIndex]
    else
        return "UNKNOWN"
    end
end

function TheClassicRaceCore:SplitFullPlayer(fullPlayer)
    local splt = TheClassicRace.SplitString(fullPlayer, "-")

    return splt[1], splt[2]
end


function TheClassicRaceCore:Now()
    return GetServerTime()
end
