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

    -- RequestUpdate throttle time window
    Throttle = 60,

    AceConfig = "The Classic Race",
    LDB = "TheClassicRace",

    Network = {
        Prefix = "TCRace",
        Channel = {
            Name = "world",
            Id = nil, -- will be set at runtime to channel ID if joined
        },
        Events = {
            PlayerInfo = "TCRACE_NET_PLAYER_INFO",
            RequestUpdate = "TCRACE_NET_REQUEST_UPDATE",
        },
    },
    Events = {
        SlashWhoResult = "WHO_RESULT",
        Ding = "DING",
        ScanFinished = "SCAN_FINISHED",
        RaceFinished = "RACE_FINISHED",
        LeaderboardSizeDecreased = "LEADERBOARD_SIZE_DECREASED",
        RefreshGUI = "REFRESH_GUI",
    },
}
TheClassicRace.Config = TheClassicRaceConfig
