-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
]]--
---@class TheClassicRaceSerializer
---@field Config TheClassicRaceConfig
local TheClassicRaceSerializer = {}
TheClassicRace.Serializer = TheClassicRaceSerializer

function TheClassicRaceSerializer.SerializePlayerInfo(playerInfo, dingedAtOffset)
    local level = playerInfo.level
    local classIndex = playerInfo.classIndex

    -- ensure level is always zero padded to 2 digits
    if level < 10 then
        level = "0" .. level
    end

    return level ..
            classIndex ..
            playerInfo.name ..
            -- apply offset
            playerInfo.dingedAt - (dingedAtOffset or 0)
end

function TheClassicRaceSerializer.DeserializePlayerInfo(str, dingedAtOffset)
    -- split string by regex
    -- name is non numeric and not a minus
    -- dingedAt is number with potentially a minus
    local lvlandClass, name, dingedAt = string.match(str, "(%d+)([^%d-]+)(%-?%d+)")

    -- level is always 2 digits
    local level = tonumber(string.sub(lvlandClass, 1, 2))
    -- class index can be 1 or 2 digits
    local classIndex = tonumber(string.sub(lvlandClass, 3))

    return {
        name = name,
        level = level,
        classIndex = classIndex,
        -- apply offset
        dingedAt = tonumber(dingedAt) + (dingedAtOffset or 0),
    }
end

function TheClassicRaceSerializer.SerializePlayerInfoBatch(playerInfoBatch)
    if #playerInfoBatch == 0 then
        return ""
    end

    -- determine offset by finding lowest dingedAt
    local dingedAtOffset = nil
    for _, playerInfo in ipairs(playerInfoBatch) do
        if dingedAtOffset == nil then
            dingedAtOffset = playerInfo.dingedAt
        else
            dingedAtOffset = math.min(dingedAtOffset, playerInfo.dingedAt)
        end
    end

    dingedAtOffset = math.floor(dingedAtOffset)

    -- build payload
    -- zero pad offset (for tests with low timestamps)
    local res = string.sub("0000000000" .. dingedAtOffset, -10) .. "$"
    for _, playerInfo in ipairs(playerInfoBatch) do
        res = res .. TheClassicRaceSerializer.SerializePlayerInfo(playerInfo, dingedAtOffset) .. "$"
    end

    return res
end

function TheClassicRaceSerializer.DeserializePlayerInfoBatch(str)
    if str == "" then
        return {}
    end

    -- grab dingedAt from start, should always be 11 digits
    local dingedAtOffset = tonumber(string.sub(str, 1, 10))
    -- chunk off the dingedAt and $ seperator
    str = string.sub(str, 12)

    -- split the rest on $ and deserialize each record
    local res = {}
    for substr in string.gmatch(str, "([^$]+$)") do
        res[#res + 1] = TheClassicRaceSerializer.DeserializePlayerInfo(substr, dingedAtOffset)
    end

    return res
end