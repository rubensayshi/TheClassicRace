-- load test base
local TheClassicRace = require("testbase")

-- WoW API stubs
local SetIsInGuild, C_Timer = _G.SetIsInGuild, _G.C_Timer

describe("Broadcaster", function()
    ---@type TheClassicRaceConfig
    local config
    local db
    ---@type TheClassicRaceCore
    local core
    ---@type TheClassicRaceNetwork
    local network
    ---@type TheClassicRaceBroadcaster
    local broadcaster
    local time = 1000000000

    before_each(function()
        SetIsInGuild(false)

        config = TheClassicRace.Config
        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        core = TheClassicRace.Core("Nub", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        network = {SendObject = function() end}
        broadcaster = TheClassicRace.Broadcaster(config, core, db, network)
        broadcaster.ticker = C_Timer.NewTicker()
    end)

    after_each(function()
        SetIsInGuild(nil)
    end)

    it("basic broadcast", function()
        local networkSpy = spy.on(network, "SendObject")

        -- insert some data into leaderboard
        db.realm.leaderboard = {
            { name = "Leader", level = 13, observedAt = time - 1 },
            { name = "Nub1", level = 13, observedAt = time - 1 },
        }

        -- set lastRequestUpdate
        db.realm.lastRequestUpdate = time

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[1].name, db.realm.leaderboard[1].level, nil }), "CHANNEL")

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[2].name, db.realm.leaderboard[2].level, nil }), "CHANNEL")

        broadcaster:Broadcast()

        assert.spy(networkSpy).called_at_most(2)
        assert.equals(true, broadcaster:IsDone())
    end)

    it("external observed, won't broadcast", function()
        local networkSpy = spy.on(network, "SendObject")

        -- insert some data into leaderboard
        db.realm.leaderboard = {
            { name = "Leader", level = 13, observedAt = time - 1 },
            { name = "Nub1", level = 13, observedAt = time - 1 },
        }

        -- set lastRequestUpdate
        db.realm.lastRequestUpdate = time

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[1].name, db.realm.leaderboard[1].level, nil }), "CHANNEL")

        -- something external caused observedAt to be bumped for player 2
        db.realm.leaderboard[2].observedAt = time

        broadcaster:Broadcast()

        assert.spy(networkSpy).called_at_most(2)
        assert.equals(true, broadcaster:IsDone())
    end)

    it("request update mid broadcast", function()
        local networkSpy = spy.on(network, "SendObject")

        -- insert some data into leaderboard
        db.realm.leaderboard = {
            { name = "Leader", level = 13, observedAt = time - 1 },
            { name = "Nub1", level = 13, observedAt = time - 1 },
        }

        -- set lastRequestUpdate
        db.realm.lastRequestUpdate = time

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[1].name, db.realm.leaderboard[1].level, nil }), "CHANNEL")

        -- something external caused observedAt to be bumped for player 2
        -- which would cause the broadcast to be done
        db.realm.leaderboard[2].observedAt = time

        -- but lastRequestUpdate is also bumped, so we restart the broadcasting sequence from first player
        time = time + 1
        db.realm.lastRequestUpdate = time

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[1].name, db.realm.leaderboard[1].level, nil }), "CHANNEL")

        broadcaster:Broadcast()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), config.Network.Events.PlayerInfo,
                match.is_same({ db.realm.leaderboard[2].name, db.realm.leaderboard[2].level, nil }), "CHANNEL")

        broadcaster:Broadcast()

        assert.spy(networkSpy).called_at_most(3)
        assert.equals(true, broadcaster:IsDone())
    end)
end)
