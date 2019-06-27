_G.GetRealmName = function()
    return "NubVille"
end

_G.UnitName = function()
    return "Nub"
end

_G.UnitClass = function()
    return "Druid"
end

_G.UnitRace = function()
    return "Night Elf"
end

_G.UnitFactionGroup = function()
    return "Alliance"
end

local defaultIsInGuild = true
local isInGuild = defaultIsInGuild
_G.IsInGuild = function()
    return isInGuild
end

_G.SetIsInGuild = function(_isInGuild)
    if _isInGuild == nil then
        _isInGuild = defaultIsInGuild
    end
    isInGuild = _isInGuild
end

_G.GetLocale = function()
    return "enUS"
end

_G.GetCurrentRegion = function()
    return 3 -- EU, from ("US", "KR", "EU", "TW", "CN")
end

_G.UnitFullName = function(target)
    -- @TODO: returns name-server for cross realm, should make a test for this
    if target == "player" then
        return _G.UnitName(), _G.GetRealmName()
    else
        error("unsupported", 1)
    end
end

local defaultRealZoneText = "Ironforge"
local realZoneText = defaultRealZoneText
_G.SetRealZoneText = function(_realZoneText)
    if _realZoneText == nil then
        _realZoneText = defaultRealZoneText
    end
    realZoneText = _realZoneText
end

_G.GetRealZoneText = function()
    return realZoneText
end

local defaultNumGroupMembers = 0
local numGroupMembers = defaultNumGroupMembers
_G.SetNumGroupMembers = function(_numGroupMembers)
    if _numGroupMembers == nil then
        _numGroupMembers = defaultNumGroupMembers
    end
    numGroupMembers = _numGroupMembers
end

_G.GetNumGroupMembers = function()
    return numGroupMembers
end

_G.GetRaidRosterInfo = function(i)
    -- @TODO: returns name-server for cross realm, should make a test for this
    if i == 1 then
        return _G.UnitName()
    end

    return "Player-" .. i
end