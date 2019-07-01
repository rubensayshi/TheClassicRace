local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceDefaultDB
local TheClassicRaceDefaultDB = {
    profile = {
        options = {
            minimap = {
                hide = false,
            },
            networking = true,
            notifications = true,
        },
    },
    realm = {
        finished = false,
        levelThreshold = 2,
        highestLevel = 1,
        lastRequestUpdate = 0,
        leaderboard = {},
    },
}

TheClassicRace.DefaultDB = TheClassicRaceDefaultDB
