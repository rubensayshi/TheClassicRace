-- load test base
local TheClassicRace = require("testbase")

-- aliases
local Events = TheClassicRace.Config.Events

function mergeConfigs(...)
    local config = {}
    for _, c in pairs({...}) do
        for k, v in pairs(c) do
            config[k] = v
        end
    end

    return config
end

describe("Tracker", function()
    ---@type TheClassicRaceConfig
    local config
    local db
    ---@type TheClassicRaceCore
    local core
    ---@type TheClassicRaceEventBus
    local eventbus
    ---@type TheClassicRaceNetwork
    local network
    ---@type TheClassicRaceTracker
    local tracker
    local time = 1000000000

    before_each(function()
        config = mergeConfigs(TheClassicRace.Config, {MaxLeaderboardSize = 5})
        -- little hacky to adjust DefaultDB because it's constant
        defaultDb = mergeConfigs(TheClassicRace.DefaultDB, {})
        defaultDb.profile.options.leaderboardSize = config.MaxLeaderboardSize

        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", defaultDb, true)
        db:ResetDB()
        core = TheClassicRace.Core("Nub", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        eventbus = TheClassicRace.EventBus()
        network = {SendObject = function() end}
        tracker = TheClassicRace.Tracker(config, core, db, eventbus, network)
    end)

    after_each(function()
        -- reset any mocking of IsInGuild we did
        _G.SetIsInGuild(nil)
    end)

    describe("leaderboard", function()
        it("adds players", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub2", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub3", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub4", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub5", level = 5}, false)

            assert.equals(5, #db.realm.leaderboard)
            assert.same({
                {name = "Nub1", level = 5, dingedAt = time},
                {name = "Nub2", level = 5, dingedAt = time},
                {name = "Nub3", level = 5, dingedAt = time},
                {name = "Nub4", level = 5, dingedAt = time},
                {name = "Nub5", level = 5, dingedAt = time},
            }, db.realm.leaderboard)
        end)

        it("doesn't add duplicates", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)

            assert.equals(1, #db.realm.leaderboard)
        end)

        it("doesn't add beyond max", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub2", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub3", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub4", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub5", level = 5}, false)
            -- max
            tracker:HandlePlayerInfo({name = "Nub6", level = 5}, false)
            assert.equals(5, #db.realm.leaderboard)
            assert.same({
                {name = "Nub1", level = 5, dingedAt = time},
                {name = "Nub2", level = 5, dingedAt = time},
                {name = "Nub3", level = 5, dingedAt = time},
                {name = "Nub4", level = 5, dingedAt = time},
                {name = "Nub5", level = 5, dingedAt = time},
            }, db.realm.leaderboard)
        end)

        it("truncates when config is decreased", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub2", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub3", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub4", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub5", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub6", level = 5}, false)

            -- leaderboard is capped at 5
            assert.equals(5, #db.realm.leaderboard)

            -- adjust the option
            db.profile.options.leaderboardSize = 4

            -- nothing changed yet until we fire event
            assert.equals(5, #db.realm.leaderboard)

            -- fire event
            eventbus:PublishEvent(config.Events.LeaderboardSizeDecreased)

            -- leaderboard should be truncated
            assert.equals(4, #db.realm.leaderboard)
        end)

        it("bumps on ding", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub1", level = 6}, false)

            assert.equals(1, #db.realm.leaderboard)
            assert.equals(6, db.realm.leaderboard[1].level)
        end)

        it("reorders on ding", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub2", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub3", level = 5}, false)

            tracker:HandlePlayerInfo({name = "Nub2", level = 6}, false)
            assert.equals(3, #db.realm.leaderboard)
            assert.same({
                {name = "Nub2", level = 6, dingedAt = time},
                {name = "Nub1", level = 5, dingedAt = time},
                {name = "Nub3", level = 5, dingedAt = time},
            }, db.realm.leaderboard)
        end)

        it("truncates on ding", function()
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub2", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub3", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub4", level = 5}, false)
            tracker:HandlePlayerInfo({name = "Nub5", level = 5}, false)

            tracker:HandlePlayerInfo({name = "Nub6", level = 6}, false)
            assert.equals(5, #db.realm.leaderboard)
            assert.same({
                {name = "Nub6", level = 6, dingedAt = time},
                {name = "Nub1", level = 5, dingedAt = time},
                {name = "Nub2", level = 5, dingedAt = time},
                {name = "Nub3", level = 5, dingedAt = time},
                {name = "Nub4", level = 5, dingedAt = time},
            }, db.realm.leaderboard)
        end)

        it("should broadcast internal event", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            tracker:HandlePlayerInfo({name = "Nub1", level = 6}, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            tracker:HandlePlayerInfo({name = "Nub2", level = 7}, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            eventBusSpy:clear()
            tracker:HandlePlayerInfo({name = "Nub1", level = 6}, false)
            assert.spy(eventBusSpy).was_not_called()

            tracker:HandlePlayerInfo({name = "Nub1", level = 7}, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 2)
        end)

        it("shouldn't broadcast to network OnNetPlayerInfo", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnNetPlayerInfo({{"Nub1", 5, nil}, })
            assert.spy(networkSpy).was_not_called()
        end)

        it("should broadcast to network OnSlashWhoResult", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnSlashWhoResult({name = "Nub1", level = 5})
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    match.is_table(), "GUILD")
        end)

        it("should broadcast to network OnSlashWhoResult, not to guild when not in guild", function()
            local networkSpy = spy.on(network, "SendObject")

            _G.SetIsInGuild(false)

            tracker:OnSlashWhoResult({name = "Nub1", level = 5})
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).called_at_most(1)
        end)
    end)

    describe("RaceFinished", function()
        it("produces RaceFinished event once", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:OnScanFinished(false)
            assert.spy(eventBusSpy).called_at_most(0)

            tracker:OnScanFinished(true)
            tracker:OnScanFinished(true)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.RaceFinished)
            assert.spy(eventBusSpy).called_at_most(1)
        end)
    end)
end)
