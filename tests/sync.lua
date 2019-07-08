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
        core = TheClassicRace.Core(TheClassicRace.Config, "Nub", "NubVille")
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

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
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

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "GUILD")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("can init and start sync with partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Dude")

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(3)
    end)

    it("can init and chooses preferred partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        -- Dude provides a
        eventbus:PublishEvent(NetEvents.OfferSync, {11, time}, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Chick")

        -- overload SelectPartnerFromList to avoid randomness, hacky but works...
        sync.SelectPartnerFromList = function(self, offers)
            return table.remove(offers, 1)
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Chick")
        assert.spy(networkSpy).called_at_most(3)
        networkSpy:clear()

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(3)
    end)

    it("can init and sync with partner, won't (re)try other partners", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Chick")

        -- overload SelectPartnerFromList to avoid randomness, hacky but works...
        sync.SelectPartnerFromList = function(self, offers)
            return table.remove(offers, 1)
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(3)
        networkSpy:clear()

        -- receive payload from Dude
        eventbus:PublishEvent(NetEvents.SyncPayload, "", "Dude")

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("can init and retry sync with unresponsive partner", function()
        local networkSpy = spy.on(network, "SendObject")

        sync:InitSync()

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.RequestSync, 11, "CHANNEL")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Dude")
        eventbus:PublishEvent(NetEvents.OfferSync, {11, nil}, "Chick")

        -- overload SelectPartnerFromList to avoid randomness, hacky but works...
        sync.SelectPartnerFromList = function(self, offers)
            return table.remove(offers, 1)
        end

        -- advance our clock so the sync happens
        AdvanceClock(TheClassicRace.Config.RequestSyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(3)
        networkSpy:clear()

        -- advance our clock so the retry happens
        AdvanceClock(TheClassicRace.Config.RetrySyncWait)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.StartSync, 11, "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Chick")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Chick")
        assert.spy(networkSpy).called_at_most(3)
    end)

    it("can offer and sync", function()
        local networkSpy = spy.on(network, "SendObject")

        -- mark as ready
        sync.isReady = true

        eventbus:PublishEvent(NetEvents.RequestSync, 11, "Dude")

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.OfferSync, {11, nil}, "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
        networkSpy:clear()

        eventbus:PublishEvent(NetEvents.StartSync, 11, "Dude")

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, "", "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(2)
    end)

    it("won't offer when not ready offer and sync", function()
        local networkSpy = spy.on(network, "SendObject")

        eventbus:PublishEvent(NetEvents.RequestSync, 11, "Dude")

        assert.spy(networkSpy).called_at_most(0)
    end)

    it("won't offer when networking is disabled", function()
        local networkSpy = spy.on(network, "SendObject")

        -- disable networking in options
        db.profile.options.networking = false

        -- mark as ready
        sync.isReady = true

        eventbus:PublishEvent(NetEvents.RequestSync, 11, "Dude")

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

    it("produces proper payload for global leaderboard", function()
        local networkSpy = spy.on(network, "SendObject")

        db.factionrealm.leaderboard[0].players = {
            {name = "Nub1", level = 5, dingedAt = time, classIndex = 8},
            {name = "Nub2", level = 5, dingedAt = time, classIndex = 7},
            {name = "Nub3", level = 5, dingedAt = time, classIndex = 6},
            {name = "Nub4", level = 5, dingedAt = time, classIndex = 5},
            {name = "Nub5", level = 5, dingedAt = time + 10, classIndex = 4},
        }

        sync:Sync("Dude", 0)

        local expectedPayload = TheClassicRace.Serializer.SerializePlayerInfoBatch(db.factionrealm.leaderboard[0].players)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, expectedPayload, "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
    end)

    it("produces proper payload for class leaderboard", function()
        local networkSpy = spy.on(network, "SendObject")

        db.factionrealm.leaderboard[8].players = {
            {name = "Nub1", level = 5, dingedAt = time, classIndex = 8},
        }

        sync:Sync("Dude", 8)

        local expectedPayload = TheClassicRace.Serializer.SerializePlayerInfoBatch(db.factionrealm.leaderboard[8].players)

        assert.spy(networkSpy).was_called_with(match.is_ref(network), NetEvents.SyncPayload, expectedPayload, "WHISPER", "Dude")
        assert.spy(networkSpy).called_at_most(1)
    end)

    it("consumes proper payload", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        sync:OnNetSyncPayload(TheClassicRace.Serializer.SerializePlayerInfoBatch({
            {name = "Nubone", level = 5, dingedAt = time, classIndex = 8},
            {name = "Nubtwo", level = 5, dingedAt = time, classIndex = 7},
            {name = "Nubthree", level = 5, dingedAt = time, classIndex = 6},
            {name = "Nubfour", level = 5, dingedAt = time + 10, classIndex = 5},
            {name = "Nubfive", level = 5, dingedAt = time - 11, classIndex = 4},
        }), "Dude")

        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.SyncResult,
                match.is_same({
                    {name = "Nubone", level = 5, dingedAt = time, classIndex = 8},
                    {name = "Nubtwo", level = 5, dingedAt = time, classIndex = 7},
                    {name = "Nubthree", level = 5, dingedAt = time, classIndex = 6},
                    {name = "Nubfour", level = 5, dingedAt = time + 10, classIndex = 5},
                    {name = "Nubfive", level = 5, dingedAt = time - 11, classIndex = 4},
                }), false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)
end)
