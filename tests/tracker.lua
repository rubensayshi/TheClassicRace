-- load test base
local TheClassicRace = require("testbase")

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
        config = mergeConfigs(TheClassicRace.Config, {LeaderboardSize = 5})

        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        core = TheClassicRace.Core("Nub", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        eventbus = TheClassicRace.EventBus()
        network = {SendObject = function() end}
        tracker = TheClassicRace.Tracker(config, core, db, eventbus, network)
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

        it("shouldn't broadcast to network OnDing", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnDing({"Nub1", 5, nil})
            assert.spy(networkSpy).was_not_called()
        end)

        it("should broadcast to network OnPlayerInfo", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnPlayerInfo({name = "Nub1", level = 5})
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    match.is_table(), "GUILD")
        end)
    end)

    describe("RequestUpdate", function()
        it("sends request", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:RequestUpdate()

            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.RequestUpdate,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.RequestUpdate,
                    match.is_table(), "GUILD")
        end)

        it("responds to request", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)

            tracker:OnRequestUpdate(nil, "Roobs")

            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    {"Nub1", 5, time}, "WHISPER", "Roobs")
        end)

        it("throttles requests", function()
            local networkSpy = spy.on(network, "SendObject")

            local dingedAt = time
            tracker:HandlePlayerInfo({name = "Nub1", level = 5}, false)

            tracker:OnRequestUpdate(nil, "Roobs")

            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    {"Nub1", 5, dingedAt}, "WHISPER", "Roobs")

            networkSpy:clear()
            tracker:OnRequestUpdate(nil, "Roobs")

            assert.spy(networkSpy).was_not_called()

            networkSpy:clear()
            time = time + config.Throttle
            tracker:OnRequestUpdate(nil, "Roobs")

            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                    {"Nub1", 5, dingedAt}, "WHISPER", "Roobs")
        end)
    end)
end)
