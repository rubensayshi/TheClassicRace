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
    LeaderboardSize = 50,

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
        SlashWhoResult = "TCRACE_WHO_RESULT",
        Ding = "TCRACE_DING",
        -- ScanFinished(endofrace)
        -- should use RaceFinished though if interested in when the race is finished,
        -- because that's only broadcasted once
        ScanFinished = "TCRACE_SCAN_FINISHED",
        RaceFinished = "TCRACE_RACE_FINISHED",
    },
}
TheClassicRace.Config = TheClassicRaceConfig
