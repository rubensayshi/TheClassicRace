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
    Trace = false,

    PollInterval = 60,
    SlashWHoDelay = 5,

    MaxLevel = 60,
    MaxSlashWhoResults = 50,


    Network = {
        Prefix = "TCRace",
        Channel = {
            Name = "TheClassicRaceNetwork",
            Id = 1, -- will be set at runtime to channel ID when joined
        },
        Events = {
            SetScore = "TCRACE_NE_SET_SCORE",
            RequestScores = "TCRACE_NE_REQUEST_SCORES",
        },
    },
    Events = {
        SetPlayerInfo = "TCRACE_SET_PLAYER_INFO",
    },
}
TheClassicRace.Config = TheClassicRaceConfig
