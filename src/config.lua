local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceColors
local TheClassicRaceColors = {
    WHITE = "|cFFFFFFFF",
    SYSTEM_EVENT_YELLOW = "|cFFFFFF00",
    BROWN       = "|cFFEDA55F",
    WARRIOR	    = "|cFFC79C6E",
    PALADIN	    = "|cFFF58CBA",
    HUNTER      = "|cFFABD473",
    ROGUE	    = "|cFFFFF569",
    PRIEST	    = "|cFFFFFFFF",
    DEATHKNIGHT = "|cFFC41F3B",
    SHAMAN	    = "|cFF0070DE",
    MAGE	    = "|cFF69CCF0",
    WARLOCK	    = "|cFF9482C9",
    MONK	    = "|cFF00FF96",
    DRUID       = "|cFFFF7D0A",
    DEMONHUNTER = "POO",
}
TheClassicRace.Colors = TheClassicRaceColors

---@class TheClassicRaceConfig
local TheClassicRaceConfig = {
    Debug = false,
    Trace = false,
    --@debug@
    Debug = true,
    Trace = true,
    --@end-debug@

    MaxLevel = 60,
    MaxLeaderboardSize = 50,

    -- OfferSync throttle time window
    RequestSyncWait = 5,
    RetrySyncWait = 30,
    OfferSyncThrottle = 30,

    AceConfig = "The Classic Race",
    LDB = "TheClassicRace",

    Classes = {
        "WARRIOR",
        "PALADIN",
        "HUNTER",
        "ROGUE",
        "PRIEST",
        "DEATHKNIGHT",
        "SHAMAN",
        "MAGE",
        "WARLOCK",
        "MONK",
        "DRUID",
        "DEMONHUNTER",
    },

    -- ClassIndexes is inverse of Classes
    UnknownClassIndex = 0,
    ClassIndexes = {
        WARRIOR = 1,
        PALADIN = 2,
        HUNTER = 3,
        ROGUE = 4,
        PRIEST = 5,
        DEATHKNIGHT = 6,
        SHAMAN = 7,
        MAGE = 8,
        WARLOCK = 9,
        MONK = 10,
        DRUID = 11,
        DEMONHUNTER = 12,
    },

    Network = {
        Prefix = "TCRace",
        Channel = {
            Name = "world",
            Id = nil, -- will be set at runtime to channel ID if joined
        },
        Events = {
            PlayerInfoBatch = "PINFOB",
            RequestSync = "REQSYNC",
            OfferSync = "OFFERSYNC",
            StartSync = "STARTSYNC",
            SyncPayload = "SYNC",
        },
    },
    Events = {
        SlashWhoResult = "WHO_RESULT",
        SyncResult = "SYNC_RESULT",
        BumpScan = "BUMP_SCAN",
        Ding = "DING",
        -- ScanFinished(endofrace)
        -- should use RaceFinished though if interested in when the race is finished,
        -- because that's only broadcasted once
        ScanFinished = "SCAN_FINISHED",
        RaceFinished = "RACE_FINISHED",
        LeaderboardSizeDecreased = "LEADERBOARD_SIZE_DECREASED",
        RefreshGUI = "REFRESH_GUI",
    },
}
TheClassicRace.Config = TheClassicRaceConfig
