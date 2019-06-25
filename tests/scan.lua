-- load test base
local TheClassicRace = require("testbase")

--[[
LibWhoMock is a mock for LibWho
It has an :ExpectWho method to construct a list of expected calls and their return values
And an :Assert to assert that all expected calls were consumed
]]--
local LibWhoMock = require("stubs.libwhomock")

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

    before_each(function()
        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        core = TheClassicRace.Core("Nub", "NubVille")
        -- mock core:Now() to return our mocked time
        function core:Now() return time end
        eventbus = TheClassicRace.EventBus()
        libWhoMock = LibWhoMock()
        scan = TheClassicRace.Scan(Core, db, EventBus, function(min, max, cb)
            libWhoMock:Who(min, max, cb)
        end, 1, 60)
    end)

    it("basic lvl13", function()
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(30, 60, true, {})
        libWhoMock:ExpectWho(15, 60, true, {})
        libWhoMock:ExpectWho(8, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(12, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(14, 60, true, {})
        libWhoMock:ExpectWho(13, 60, true, {{Name = "Leader", Level = 13}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("shortcuts lvl13", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found
        ]]--
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 13}})
        libWhoMock:ExpectWho(30, 60, true, {})
        libWhoMock:ExpectWho(15, 60, true, {})
        libWhoMock:ExpectWho(8, 60, true, {{Name = "Leader", Level = 13}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("basic lvl42", function()
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(30, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(45, 60, true, {})
        libWhoMock:ExpectWho(38, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(42, 60, true, {{Name = "Leader", Level = 42}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("shortcuts lvl42", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found
        ]]--
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(30, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(45, 60, true, {})
        libWhoMock:ExpectWho(38, 60, true, {{Name = "Leader", Level = 42}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("basic lvl42 with min", function()
        scan:SetMin(41)

        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 42}})
        libWhoMock:ExpectWho(50, 60, true, {})
        libWhoMock:ExpectWho(45, 60, true, {})
        libWhoMock:ExpectWho(43, 60, true, {})
        libWhoMock:ExpectWho(42, 60, true, {{Name = "Leader", Level = 42}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("shortcuts lvl42 with min", function()
        --[[
        Should stop scanning when the first results > 0 and complete = true is found,
        also when that occurs with the initial (min, max) scan from :SetMin()
        ]]--
        scan:SetMin(41)

        libWhoMock:ExpectWho(41, 60, true, {{Name = "Leader", Level = 42}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("too many max lvl", function()
        --[[
        Should know when there's too many 60s to find a leader
        @TODO: we should handle this case so that the user knows and set levelThreshold to avoid scanning forever and ever
        ]]--
        libWhoMock:ExpectWho(1, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(30, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(45, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(53, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(57, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(59, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(60, 60, false, {{Name = "Leader", Level = 60}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)

    it("too many max lvl with min", function()
        --[[
        Should know when there's too many 60s to find a leader
        ]]--
        scan:SetMin(41)

        libWhoMock:ExpectWho(41, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(50, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(55, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(58, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(59, 60, false, {{Name = "Leader", Level = 60}})
        libWhoMock:ExpectWho(60, 60, false, {{Name = "Leader", Level = 60}})

        scan:Start()
        assert.equals(true, scan:IsDone())
        libWhoMock:Assert()
    end)
end)
