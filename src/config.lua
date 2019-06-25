local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceColors
local TheClassicRaceColors = {
    WHITE = "|cFFFFFFFF",
    SYSTEM_EVENT_YELLOW = "|cFFFFFF00",
}
TheClassicRace.Colors = TheClassicRaceColors

---@class TheClassicRaceConfig
local TheClassicRaceConfig = {
    Debug = true,
    Trace = true,

    MaxLevel = 60,
    LeaderboardSize = 50,

    -- RequestUpdate throttle time window
    Throttle = 60,

    Network = {
        Prefix = "TCRace",
        Channel = {
            Name = "world",
            Id = 1, -- will be set at runtime to channel ID when joined
        },
        Events = {
            Ding = "TCRACE_DING",
            RequestUpdate = "TCRACE_REQUEST_UPDATE",
        },
    },
    Events = {
        PlayerInfo = "TCRACE_PLAYER_INFO",
    },
}
TheClassicRace.Config = TheClassicRaceConfig
