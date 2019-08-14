local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceDefaultDB
local TheClassicRaceDefaultDB = {
    profile = {
        options = {
            minimap = {
                hide = false,
            },
            networking = true,
            dontbump = false,
            globalNotifications = true,
            globalNotificationThreshold = 25,
            classNotifications = true,
            classNotificationThreshold = 10,
        },
        gui = {
            display = true,
            statusFrameStatus = {
                width = 240,
                height = 240,
            },
        },
    },
    factionrealm = {
        dbversion = "0.0.0",
        finished = false,
        leaderboard = {
            ['**'] = {
                minLevel = 2,
                highestLevel = 1,
                players = {},
            },
        },
    },
}

TheClassicRace.DefaultDB = TheClassicRaceDefaultDB
