-- load test base
local TheClassicRace = require("testbase")

--[[
LibWhoMock is a mock for LibWho
It has an :ExpectWho method to construct a list of expected calls and their return values
And an :Assert to assert that all expected calls were consumed
]]--
local LibWhoMock = require("stubs.libwhomock")

-- aliases
local Events = TheClassicRace.Config.Events

describe("Scan", function()
    local db
    ---@type TheClassicRaceCore
    local core
    ---@type TheClassicRaceEventBus
    local eventbus
    ---@type LibWhoMock
    local libWhoMock
    ---@type TheClassicRaceScan
    local scan
    local time = 1000000000

    function initScan(min, prevhighestlvl, max)
        if min == nil then
            min = 1
        end
        if prevhighestlvl == nil then
            prevhighestlvl = 1
        end
        if max == nil then
            max = 60
        end

        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        core = TheClassicRace.Core(TheClassicRace.Config, "Nubone", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        eventbus = TheClassicRace.EventBus()
        libWhoMock = LibWhoMock()
        return TheClassicRace.Scan(core, db, eventbus, function(min, max, cb)
            libWhoMock:Who(min, max, cb)
        end, min, prevhighestlvl, max)
    end

    before_each(function()
        scan = initScan()
    end)

    it("basic lvl13", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 13}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, true, {})
        libWhoMock:ExpectWho(16, 60, true, {})
        libWhoMock:ExpectWho(8, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(12, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(14, 60, true, {})
        libWhoMock:ExpectWho(13, 60, true, {{Name = "Leader", Level = 13}})
        -- scan down
        libWhoMock:ExpectWho(12, 12, false, {{Name = "Nubone", Level = 12}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("shortcuts lvl13", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found
        ]]--
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 13}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, true, {})
        libWhoMock:ExpectWho(16, 60, true, {})
        libWhoMock:ExpectWho(8, 60, true, {{Name = "Leader", Level = 13}})
        -- scan down
        libWhoMock:ExpectWho(7, 7, true, {
            {Name = "Nubone", Level = 7}})
        libWhoMock:ExpectWho(6, 7, true, {
            {Name = "Nubone", Level = 7}, {Name = "Nubtwo", Level = 6}})
        libWhoMock:ExpectWho(5, 7, false, {
            {Name = "Nubone", Level = 7}, {Name = "Nubtwo", Level = 6}, {Name = "Nubthree", Level = 5}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("basic lvl42", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 42}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(39, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(43, 60, true, {})
        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(42, 60, true, {{Name = "Leader", Level = 42}})
        -- scan down
        libWhoMock:ExpectWho(41, 41, true, {
            {Name = "Nubone", Level = 41}})
        libWhoMock:ExpectWho(40, 41, true, {
            {Name = "Nubone", Level = 41}, {Name = "Nubtwo", Level = 40}})
        libWhoMock:ExpectWho(39, 41, false, {
            {Name = "Nubone", Level = 41}, {Name = "Nubtwo", Level = 40}, {Name = "Nubthree", Level = 39}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("shortcuts lvl42", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found
        ]]--
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 42}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(39, 60, true, {{Name = "Leader", Level = 42}})
        -- scan down
        libWhoMock:ExpectWho(38, 38, false, {{Name = "Nubone", Level = 37}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("basic lvl42 with prevhighestlvl", function()
        scan = initScan(41, 41)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 42}})
        -- binary search
        libWhoMock:ExpectWho(51, 60, true, {})
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(43, 60, true, {})
        libWhoMock:ExpectWho(42, 60, true, {{Name = "Leader", Level = 42}})
        -- scan down
        libWhoMock:ExpectWho(41, 41, false, {{Name = "Nubone", Level = 41}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("shortcuts lvl42 with prevhighestlvl", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found,
        also when that occurs with the initial (min, max) scan set
        ]]--
        scan = initScan(39, 41)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(41, 60, true, {{Name = "Leader", Level = 42}})
        -- scan down
        libWhoMock:ExpectWho(40, 40, false, {{Name = "Nubone", Level = 40}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("shortcuts lvl42 with prevhighestlvl and min", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found,
        also when that occurs with the initial (min, max) scan set
        ]]--
        scan = initScan(41, 41)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(41, 60, true, {{Name = "Leader", Level = 42}})
        -- no scan down

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("basic lvl42 with prevhighestlvl and different min", function()
        scan = initScan(39, 41)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 42}})
        -- binary search
        libWhoMock:ExpectWho(50, 60, true, {})
        libWhoMock:ExpectWho(44, 60, true, {})
        libWhoMock:ExpectWho(41, 60, true, {{Name = "Leader", Level = 42}})
        -- scan down
        libWhoMock:ExpectWho(40, 40, false, {{Name = "Nubone", Level = 40}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("too many max lvl, end of race", function()
        --[[
        Should know when there's too many 60s to find a leader,
        and should broadcast ScanFinished with complete=false
        ]]--
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 60}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(46, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(54, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(58, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(60, 60, false, {{Name = "Leader", Level = 60}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, true)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("too many max lvl with prevhighestlvl", function()
        --[[
        Should know when there's too many 60s to find a leader, starting with a min=41
        ]]--
        scan = initScan(41, 41)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 60}})
        -- binary search
        libWhoMock:ExpectWho(51, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(56, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(59, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(60, 60, false, {{Name = "Leader", Level = 60}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, true)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("too many lvl40, complete", function()
        --[[
        Should know when there's too many 40s to find a leader,
        but should still broadcast ScanFinished with complete=true
        ]]--
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 40}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 40}})
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(39, 60, false, {{Name = "Leader", Level = 40}})
        libWhoMock:ExpectWho(43, 60, true, {})
        libWhoMock:ExpectWho(41, 60, true, {})
        libWhoMock:ExpectWho(40, 60, false, {{Name = "Leader", Level = 40}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("too many lvl40 with prevhighestlvl", function()
        --[[
        Should know when there's too many 40s to find a leader, starting with a min=31,
        but should still broadcast ScanFinished with complete=true
        ]]--
        scan = initScan(31, 31)

        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 40}})
        -- binary search
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(38, 60, false, {{Name = "Leader", Level = 40}})
        libWhoMock:ExpectWho(42, 60, true, {})
        libWhoMock:ExpectWho(40, 60, false, {{Name = "Leader", Level = 40}})
        libWhoMock:ExpectWho(41, 60, true, {})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("lvl42, mid-scan offline", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 42}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(46, 60, true, {})
        libWhoMock:ExpectWho(39, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(43, 60, true, {})
        -- Leader went offline, result is empty
        libWhoMock:ExpectWho(41, 60, true, {})
        -- binary search continues
        libWhoMock:ExpectWho(40, 60, true, {{Name = "Nubone", Level = 41}})
        -- scan down
        libWhoMock:ExpectWho(39, 39, true, {
            {Name = "Nubone", Level = 39}})
        libWhoMock:ExpectWho(38, 39, true, {
            {Name = "Nubone", Level = 39}, {Name = "Nubtwo", Level = 38}})
        libWhoMock:ExpectWho(37, 39, false, {
            {Name = "Nubone", Level = 39}, {Name = "Nubtwo", Level = 38}, {Name = "Nubthree", Level = 37}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("lvl40, scan down, too few players", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 40}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, true, {{Name = "Leader", Level = 40}})
        -- scan down
        for i = 0, 29 do
            local lvl = 30 - i
            libWhoMock:ExpectWho(lvl, 30, true, {})
        end

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)

    it("lvl40, scan down, just enough players", function()
        local eventBusSpy = spy.on(eventbus, "PublishEvent")

        -- shortcut
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 40}})
        -- binary search
        libWhoMock:ExpectWho(31, 60, true, {{Name = "Leader", Level = 40}})
        -- scan down until lvl19 at which we finaly have complete=true
        for i = 0, 10 do
            local lvl = 30 - i
            libWhoMock:ExpectWho(lvl, 30, true, {})
        end
        libWhoMock:ExpectWho(19, 30, false, {})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
        assert.spy(eventBusSpy).was_called_with(match.is_ref(eventbus), Events.ScanFinished, false)
        assert.spy(eventBusSpy).called_at_most(1)
    end)
end)
