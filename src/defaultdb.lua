local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceDefaultDB
local TheClassicRaceDefaultDB = {
    profile = {
        top = 50,
    },
    realm = {
        highestLevel = 1,
        data = {
            -- keyed per level
            ['**'] = {
                players = {
                    ['**'] = {
                        dingedAt = nil,
                        lastseenAt = nil,
                    },
                }
            },
        },
    },
}

TheClassicRace.DefaultDB = TheClassicRaceDefaultDB
