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
            leaderboardSize = TheClassicRace.Config.MaxLeaderboardSize,
        },
    },
    factionrealm = {
        finished = false,
        levelThreshold = 2,
        highestLevel = 1,
        leaderboard = {},
    },
}

TheClassicRace.DefaultDB = TheClassicRaceDefaultDB
