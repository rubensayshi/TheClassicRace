-- load test base
local TheClassicRace = require("testbase")

-- aliases
local Events = TheClassicRace.Config.Events
local DRUIDIDX, WARRIORIDX, PALADINIDX, PRIESTIDX =
TheClassicRace.Config.ClassIndexes["DRUID"], TheClassicRace.Config.ClassIndexes["WARRIOR"],
TheClassicRace.Config.ClassIndexes["PALADIN"],TheClassicRace.Config.ClassIndexes["PRIEST"]

function merge(...)
    local config = {}
    for _, c in pairs({...}) do
        for k, v in pairs(c) do
            config[k] = v
        end
    end

    return config
end

function leaderboardSpies(tracker, config)
    local spies = {}

    spies[0] = spy.on(tracker.lbGlobal, "ProcessPlayerInfo")

    for classIndex, _ in ipairs(config.Classes) do
        spies[classIndex] = spy.on(tracker.lbPerClass[classIndex], "ProcessPlayerInfo")
    end

    return spies
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

    function playerInfo(name, level, classIndex, dingedAt)
        if classIndex == nil then
            classIndex = 11
        end
        if dingedAt == nil then
            dingedAt = time
        end

        return {
            name = name,
            level = level,
            classIndex = classIndex,
            dingedAt = dingedAt,
        }
    end



    before_each(function()
        config = merge(TheClassicRace.Config, {MaxLeaderboardSize = 5})
        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
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
        it("adds players to global and class board", function()
            local lbSpies = leaderboardSpies(tracker, config)

            local pInfo

            pInfo = playerInfo("Nubone", 5, DRUIDIDX)
            tracker:ProcessPlayerInfoBatch({ pInfo, }, false)
            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), pInfo)
            assert.spy(lbSpies[DRUIDIDX]).was_called_with(match.is_ref(tracker.lbPerClass[DRUIDIDX]), pInfo)

            pInfo = playerInfo("Nub2", 5, WARRIORIDX)
            tracker:ProcessPlayerInfoBatch({ pInfo, }, false)
            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), pInfo)
            assert.spy(lbSpies[WARRIORIDX]).was_called_with(match.is_ref(tracker.lbPerClass[WARRIORIDX]), pInfo)

            pInfo = playerInfo("Nubthree", 5, PALADINIDX)
            tracker:ProcessPlayerInfoBatch({ pInfo, }, false)
            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), pInfo)
            assert.spy(lbSpies[PALADINIDX]).was_called_with(match.is_ref(tracker.lbPerClass[PALADINIDX]), pInfo)

            pInfo = playerInfo("Nubfour", 5, PRIESTIDX)
            tracker:ProcessPlayerInfoBatch({ pInfo, }, false)
            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), pInfo)
            assert.spy(lbSpies[PRIESTIDX]).was_called_with(match.is_ref(tracker.lbPerClass[PRIESTIDX]), pInfo)
        end)

        it("fixes missing dingedAt", function()
            local lbSpies = leaderboardSpies(tracker, config)

            tracker:ProcessPlayerInfo({name = "Nubone", level = 5, classIndex = DRUIDIDX})

            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal),
                    playerInfo("Nubone", 5, DRUIDIDX, time))
        end)

        it("fixes class to classIndex", function()
            local lbSpies = leaderboardSpies(tracker, config)

            tracker:ProcessPlayerInfo({name = "Nubone", level = 5, class = "DRUID"})

            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal),
                    playerInfo("Nubone", 5, DRUIDIDX, time))
        end)

        it("should broadcast internal event", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:ProcessPlayerInfoBatch({ playerInfo("Nubone", 5), }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1, 1)

            tracker:ProcessPlayerInfoBatch({ playerInfo("Nubone", 6), }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1, 1)

            tracker:ProcessPlayerInfoBatch({ playerInfo("Nub2", 7), }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1, 1)

            eventBusSpy:clear()
            tracker:ProcessPlayerInfoBatch({ playerInfo("Nubone", 6), }, false)
            assert.spy(eventBusSpy).was_not_called()

            tracker:ProcessPlayerInfoBatch({ playerInfo("Nubone", 7), }, false)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 2, 2)
        end)

        it("shouldn't broadcast to network OnNetPlayerInfo", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnNetPlayerInfoBatch({
                TheClassicRace.Serializer.SerializePlayerInfoBatch({
                    {name = "Nubone", level = 7, classIndex = 11, dingedAt = 100},
                }),
                false
            })
            assert.spy(networkSpy).was_not_called()
        end)

        it("should bump ticker on OnNetPlayerInfo", function()
            local eventBusSpy = spy.on(eventbus, "PublishEvent")

            tracker:OnNetPlayerInfoBatch({
                TheClassicRace.Serializer.SerializePlayerInfoBatch({
                    {name = "Nubone", level = 7, classIndex = DRUIDIDX, dingedAt = 100},
                }), false, DRUIDIDX
            })

            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.BumpScan, DRUIDIDX)
            assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), config.Events.Ding,
                    match.is_table(), 1, 1)

            assert.spy(eventBusSpy).called_at_most(2)
        end)

        it("should broadcast to network OnSlashWhoResult", function()
            local networkSpy = spy.on(network, "SendObject")

            tracker:OnSlashWhoResult({ playerInfo("Nubone", 5), })
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfoBatch,
                    match.is_table(), "CHANNEL")
            assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfoBatch,
                    match.is_table(), "GUILD")
        end)

        it("should broadcast to network OnSlashWhoResult, not to guild when not in guild", function()
            local networkSpy = spy.on(network, "SendObject")

            _G.SetIsInGuild(false)

            tracker:OnSlashWhoResult({ playerInfo("Nubone", 5), })
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

    describe("Sync", function()
        it("adds players", function()
            local lbSpies = leaderboardSpies(tracker, config)

            local nub3 = playerInfo("Nubthree", 5)
            local nub4 = playerInfo("Nubfour", 5, PALADINIDX)
            local nub5 = playerInfo("Nubfive", 5, PRIESTIDX, time - 100)
            tracker:OnSyncResult({
                nub3, nub4, nub5,
            }, false)

            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), nub3)
            assert.spy(lbSpies[DRUIDIDX]).was_called_with(match.is_ref(tracker.lbPerClass[DRUIDIDX]), nub3)

            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), nub4)
            assert.spy(lbSpies[PALADINIDX]).was_called_with(match.is_ref(tracker.lbPerClass[PALADINIDX]), nub4)

            assert.spy(lbSpies[0]).was_called_with(match.is_ref(tracker.lbGlobal), nub5)
            assert.spy(lbSpies[PRIESTIDX]).was_called_with(match.is_ref(tracker.lbPerClass[PRIESTIDX]), nub5)

            assert.equals(3, #db.factionrealm.leaderboard[0].players)
            assert.same({
                {name = "Nubthree", level = 5, dingedAt = time, classIndex = DRUIDIDX},
                {name = "Nubfour", level = 5, dingedAt = time, classIndex = PALADINIDX},
                {name = "Nubfive", level = 5, dingedAt = time - 100, classIndex = PRIESTIDX},
            }, db.factionrealm.leaderboard[0].players)
        end)
    end)
end)
