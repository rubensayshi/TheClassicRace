-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local time = _G.time

---@class TheClassicRaceCore
local TheClassicRaceCore = {}
TheClassicRaceCore.__index = TheClassicRaceCore
TheClassicRace.Core = TheClassicRaceCore

setmetatable(TheClassicRaceCore, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceCore.new(player, realm)
    local self = setmetatable({}, TheClassicRaceCore)

    self.realm = realm
    self.realme = self:PlayerFull(player, realm)
    self.me = self.realme

    return self
end

function TheClassicRaceCore:PlayerFull(name, realm)
    if realm == nil then
        realm = self.realm
    end

    return name .. "-" .. realm
end

function TheClassicRaceCore:Me()
    return self.me
end

function TheClassicRaceCore:RealMe()
    return self.realme
end

function TheClassicRaceCore:Now()
    return time()
end
