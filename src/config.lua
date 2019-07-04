local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceColors
local TheClassicRaceColors = {
    WHITE = "|cFFFFFFFF",
    SYSTEM_EVENT_YELLOW = "|cFFFFFF00",
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

    Network = {
        Prefix = "TCRace",
        Channel = {
            Name = "world",
            Id = nil, -- will be set at runtime to channel ID if joined
        },
        Events = {
            PlayerInfo = "PINFO",
            RequestSync = "REQSYNC",
            OfferSync = "OFFERSYNC",
            StartSync = "STARTSYNC",
            SyncPayload = "SYNC",
        },
    },
    Events = {
        SlashWhoResult = "WHO_RESULT",
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
