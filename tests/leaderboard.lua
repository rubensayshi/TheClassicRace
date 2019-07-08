-- load test base
local TheClassicRace = require("testbase")

-- aliases
local Events = TheClassicRace.Config.Events

function merge(...)
    local config = {}
    for _, c in pairs({...}) do
        for k, v in pairs(c) do
            config[k] = v
        end
    end

    return config
end

describe("Leaderboard", function()
    ---@type TheClassicRaceConfig
    local config
    local db
    local dbboard
    ---@type TheClassicRaceLeaderboard
    local leaderboard
    local time = 1000000000

    local base = {dingedAt = time, classIndex = 11}

    before_each(function()
        config = merge(TheClassicRace.Config, {MaxLeaderboardSize = 5})
        db = LibStub("AceDB-3.0"):New("TheClassicRace_DB", TheClassicRace.DefaultDB, true)
        db:ResetDB()
        dbboard = db.factionrealm.leaderboard[0]
        leaderboard = TheClassicRace.Leaderboard(config, dbboard)
    end)

    describe("leaderboard", function()
        it("adds players", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub2", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub3", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub4", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub5", level = 5, classIndex = 6}, base), false)

            assert.equals(5, #dbboard.players)
            assert.same({
                merge({name = "Nub1", level = 5, classIndex = 11}, base),
                merge({name = "Nub2", level = 5, classIndex = 11}, base),
                merge({name = "Nub3", level = 5, classIndex = 11}, base),
                merge({name = "Nub4", level = 5, classIndex = 11}, base),
                merge({name = "Nub5", level = 5, classIndex = 6}, base),
            }, dbboard.players)
        end)

        it("doesn't add duplicates", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)

            assert.equals(1, #dbboard.players)
        end)

        it("doesn't add beyond max", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub2", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub3", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub4", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub5", level = 5}, base), false)
            -- max
            leaderboard:ProcessPlayerInfo(merge({name = "Nub6", level = 5}, base), false)
            assert.equals(5, #dbboard.players)
            assert.same({
                merge({name = "Nub1", level = 5, classIndex = 11}, base),
                merge({name = "Nub2", level = 5, classIndex = 11}, base),
                merge({name = "Nub3", level = 5, classIndex = 11}, base),
                merge({name = "Nub4", level = 5, classIndex = 11}, base),
                merge({name = "Nub5", level = 5, classIndex = 11}, base),
            }, dbboard.players)
        end)

        it("bumps on ding", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 6}, base), false)

            assert.equals(1, #dbboard.players)
            assert.equals(6, dbboard.players[1].level)
        end)

        it("reorders on ding", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub2", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub3", level = 5}, base), false)

            leaderboard:ProcessPlayerInfo(merge({name = "Nub2", level = 6}, base), false)
            assert.equals(3, #dbboard.players)
            assert.same({
                merge({name = "Nub2", level = 6, classIndex = 11}, base),
                merge({name = "Nub1", level = 5, classIndex = 11}, base),
                merge({name = "Nub3", level = 5, classIndex = 11}, base),
            }, dbboard.players)
        end)

        it("truncates on ding", function()
            leaderboard:ProcessPlayerInfo(merge({name = "Nub1", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub2", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub3", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub4", level = 5}, base), false)
            leaderboard:ProcessPlayerInfo(merge({name = "Nub5", level = 5}, base), false)

            leaderboard:ProcessPlayerInfo(merge({name = "Nub6", level = 6}, base), false)
            assert.equals(5, #dbboard.players)

            assert.same({
                merge({name = "Nub6", level = 6, classIndex = 11}, base),
                merge({name = "Nub1", level = 5, classIndex = 11}, base),
                merge({name = "Nub2", level = 5, classIndex = 11}, base),
                merge({name = "Nub3", level = 5, classIndex = 11}, base),
                merge({name = "Nub4", level = 5, classIndex = 11}, base),
            }, dbboard.players)
        end)
    end)
end)
