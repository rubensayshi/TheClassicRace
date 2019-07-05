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
        core = TheClassicRace.Core(TheClassicRace.Config, "Nub", "NubVille")
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
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 5, class = "WARRIOR"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub3", level = 5, class = "PALADIN"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub4", level = 5, class = "PRIEST"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub5", level = 5, classIndex = 6}, }, false)

            assert.equals(5, #db.factionrealm.leaderboard)
            assert.same({
                {name = "Nub1", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub2", level = 5, dingedAt = time, classIndex = 1},
                {name = "Nub3", level = 5, dingedAt = time, classIndex = 2},
                {name = "Nub4", level = 5, dingedAt = time, classIndex = 5},
                {name = "Nub5", level = 5, dingedAt = time, classIndex = 6},
            }, db.factionrealm.leaderboard)
        end)

        it("doesn't add duplicates", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)

            assert.equals(1, #db.factionrealm.leaderboard)
        end)

        it("doesn't add beyond max", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub3", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub4", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub5", level = 5, class = "DRUID"}, }, false)
            -- max
            tracker:ProcessPlayerInfoBatch({{name = "Nub6", level = 5, class = "DRUID"}, }, false)
            assert.equals(5, #db.factionrealm.leaderboard)
            assert.same({
                {name = "Nub1", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub2", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub3", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub4", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub5", level = 5, dingedAt = time, classIndex = 11},
            }, db.factionrealm.leaderboard)
        end)

        it("truncates when config is decreased", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub3", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub4", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub5", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub6", level = 5, class = "DRUID"}, }, false)

            -- leaderboard is capped at 5
            assert.equals(5, #db.factionrealm.leaderboard)

            -- adjust the option
            db.profile.options.leaderboardSize = 4

            -- nothing changed yet until we fire event
            assert.equals(5, #db.factionrealm.leaderboard)

            -- fire event
            eventbus:PublishEvent(config.Events.LeaderboardSizeDecreased)

            -- leaderboard should be truncated
            assert.equals(4, #db.factionrealm.leaderboard)
        end)

        it("bumps on ding", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 6, class = "DRUID"}, }, false)

            assert.equals(1, #db.factionrealm.leaderboard)
            assert.equals(6, db.factionrealm.leaderboard[1].level)
        end)

        it("reorders on ding", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub3", level = 5, class = "DRUID"}, }, false)

            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 6, class = "DRUID"}, }, false)
            assert.equals(3, #db.factionrealm.leaderboard)
            assert.same({
                {name = "Nub2", level = 6, dingedAt = time, classIndex = 11},
                {name = "Nub1", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub3", level = 5, dingedAt = time, classIndex = 11},
            }, db.factionrealm.leaderboard)
        end)

        it("truncates on ding", function()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub3", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub4", level = 5, class = "DRUID"}, }, false)
            tracker:ProcessPlayerInfoBatch({{name = "Nub5", level = 5, class = "DRUID"}, }, false)

            tracker:ProcessPlayerInfoBatch({{name = "Nub6", level = 6, class = "DRUID"}, }, false)
            assert.equals(5, #db.factionrealm.leaderboard)

            assert.same({
                {name = "Nub6", level = 6, dingedAt = time, classIndex = 11},
                {name = "Nub1", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub2", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub3", level = 5, dingedAt = time, classIndex = 11},
                {name = "Nub4", level = 5, dingedAt = time, classIndex = 11},
            }, db.factionrealm.leaderboard)
        end)

        it("should broadcast internal event", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 5, class = "DRUID"}, }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 6, class = "DRUID"}, }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            tracker:ProcessPlayerInfoBatch({{name = "Nub2", level = 7, class = "DRUID"}, }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            eventBusSpy:clear()
            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 6, class = "DRUID"}, }, false)
            assert.spy(eventBusSpy).was_not_called()

            tracker:ProcessPlayerInfoBatch({{name = "Nub1", level = 7, class = "DRUID"}, }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 2)
        end)

        it("shouldn't broadcast to network OnNetPlayerInfo", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnNetPlayerInfoBatch({{"Nub1", 5, nil}, false})
            assert.spy(networkSpy).was_not_called()
        end)

        it("should bump ticker on OnNetPlayerInfo", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:OnNetPlayerInfoBatch({{"Nub1", 5, nil}, false})

            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.BumpScan)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1)

            assert.spy(eventBusSpy).called_at_most(2)
        end)

        it("should broadcast to network OnSlashWhoResult", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnSlashWhoResult({{name = "Nub1", level = 5, class = "DRUID"}, })
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfoBatch,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfoBatch,
                    match.is_table(), "GUILD")
        end)

        it("should broadcast to network OnSlashWhoResult, not to guild when not in guild", function()
            local networkSpy = spy.on(network, "SendObject")

            _G.SetIsInGuild(false)

            tracker:OnSlashWhoResult({{name = "Nub1", level = 5, class = "DRUID"}, })
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfoBatch,
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
