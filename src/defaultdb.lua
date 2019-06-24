local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceDefaultDB
local TheClassicRaceDefaultDB = {
    profile = {
        top = 50,
    },
    realm = {
        levelThreshold = 2,
        highestLevel = 1,
        leader = nil, -- leader of the race in network format
        players = {
            ['**'] = {
                level = nil,
                dingedAt = nil,
                lastseenAt = nil,
            },
        },
    },
}

TheClassicRace.DefaultDB = TheClassicRaceDefaultDB
