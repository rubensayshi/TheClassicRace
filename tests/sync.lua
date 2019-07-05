-- load test base
local TheClassicRace = require("testbase")

-- aliases
local Events = TheClassicRace.Config.Events
local NetEvents = TheClassicRace.Config.Network.Events

describe("Sync", function()
    local db
    ---@type TheClassicRaceConfig
    local core
    ---@type TheClassicRaceEventBus
    local eventbus
    ---@type TheClassicRaceNetwork
    local network
    ---@type TheClassicRaceSync
    local sync
    local time = 1000000000

    local AdvanceClock

    before_each(function()
        -- easier to only test channel
        _G.SetIsInGuild(false)
        -- reset
        _G.C_Timer.Reset()

        -- stubs
        AdvanceClock = function(seconds)
            time = time + seconds
            _G.C_Timer.Advance(seconds)
        end

        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        core = TheClassicRace.Core("Nub", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        eventbus = TheClassicRace.EventBus()
        network = {SendObject = function() end}
        sync = TheClassicRace.Sync(TheClassicRace.Config, core, db, eventbus, network)
    end)

    after_each(function()
        -- reset any mocking of IsInGuild we did
        _G.SetIsInGuild(nil)
    end)

    it("can request sync, marks ready when no partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.equals(true, sync.isReady)
    end)

    it("can request sync", function()
        local networkSpy = spy.on(network, "SendObject")

        _G.SetIsInGuild(true)

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "GUILD")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("can init and start sync with partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Dude")

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("can init and chooses preferred partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        -- Dude provides a
        eventbus:PublishEvent(NetEvents.OfferSync, time, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Chick")

        -- overload SelectPartner to avoid randomness, hacky but works...
        sync.SelectPartner = function(self, offers)
            return table.remove(offers, 1).name
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Chick")
        assert.spy(networkSpy).called_at_most(2)
        networkSpy:clear()

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("can init and sync with partner, won't (re)try other partners", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Chick")

        -- overload SelectPartner to avoid randomness, hacky but works...
        sync.SelectPartner = function(self, offers)
            return table.remove(offers, 1).name
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(2)
        networkSpy:clear()

        -- receive payload from Dude
        eventbus:PublishEvent(NetEvents.SyncPayload, {}, "Dude")

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("can init and retry sync with unresponsive partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, true, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, nil, "Chick")

        -- overload SelectPartner to avoid randomness, hacky but works...
        sync.SelectPartner = function(self, offers)
            return table.remove(offers, 1).name
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(2)
        networkSpy:clear()

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, true, "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Chick")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("can offer and sync", function()
        local networkSpy = spy.on(network, "SendObject")

        -- mark as ready
        sync.isReady = true

        eventbus:PublishEvent(NetEvents.RequestSync, true, "Dude")

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.OfferSync, nil, "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.StartSync, true, "Dude")

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_table(), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
    end)

    it("won't offer when not ready offer and sync", function()
        local networkSpy = spy.on(network, "SendObject")

        eventbus:PublishEvent(NetEvents.RequestSync, true, "Dude")

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("won't offer when networking is disabled", function()
        local networkSpy = spy.on(network, "SendObject")

        -- disable networking in options
        db.profile.options.networking = false

        -- mark as ready
        sync.isReady = true

        eventbus:PublishEvent(NetEvents.RequestSync, true, "Dude")

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("won't request sync when networking is disabled", function()
        local networkSpy = spy.on(network, "SendObject")

        -- disable networking in options
        db.profile.options.networking = false

        sync:InitSync()

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("won't request sync when networking race is finished", function()
        local networkSpy = spy.on(network, "SendObject")

        -- mark race finished
        db.factionrealm.finished = true

        sync:InitSync()

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("produces proper payload", function()
        local networkSpy = spy.on(network, "SendObject")

        db.factionrealm.leaderboard = {
            {name = "Nub1", level = 5, dingedAt = time},
            {name = "Nub2", level = 5, dingedAt = time},
            {name = "Nub3", level = 5, dingedAt = time},
            {name = "Nub4", level = 5, dingedAt = time},
            {name = "Nub5", level = 5, dingedAt = time},
        }

        sync:Sync("Dude")

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, match.is_same({
            {"Nub1", 5, time},
            {"Nub2", 5, time},
            {"Nub3", 5, time},
            {"Nub4", 5, time},
            {"Nub5", 5, time},
        }), "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
    end)

    it("consumes proper payload", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        sync:OnSyncPayload({
            {"Nub1", 5, time},
            {"Nub2", 5, time},
            {"Nub3", 5, time},
            {"Nub4", 5, time},
            {"Nub5", 5, time},
        }, "Dude")

        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), NetEvents.PlayerInfo,
                match.is_same({{"Nub1", 5, time, }}), "Dude", false)
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), NetEvents.PlayerInfo,
                match.is_same({{"Nub2", 5, time, }}), "Dude", false)
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), NetEvents.PlayerInfo,
                match.is_same({{"Nub3", 5, time, }}), "Dude", false)
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), NetEvents.PlayerInfo,
                match.is_same({{"Nub4", 5, time, }}), "Dude", false)
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), NetEvents.PlayerInfo,
                match.is_same({{"Nub5", 5, time, }}), "Dude", false)
        assert.spy(eventBusSpy).called_at_most(5)
    end)
end)
