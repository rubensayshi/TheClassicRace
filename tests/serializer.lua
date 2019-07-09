-- load test base
local TheClassicRace = require("testbase")

-- libs
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

-- aliases
local SerPInfo = TheClassicRace.Serializer.SerializePlayerInfo
local DeserPInfo = TheClassicRace.Serializer.DeserializePlayerInfo
local SerPInfoBatch = TheClassicRace.Serializer.SerializePlayerInfoBatch
local DeserPInfoBatch = TheClassicRace.Serializer.DeserializePlayerInfoBatch

function mergeConfigs(...)
    local config = {}
    for _, c in pairs({...}) do
        for k, v in pairs(c) do
            config[k] = v
        end
    end

    return config
end

local time = 1000000000

describe("Serializer", function()
    describe("PlayerInfo", function()
        it("serializes and deserializes", function()
            local nub1 = {name = "Nubone", level = 5, dingedAt = time, classIndex = 11}
            local nub2 = {name = "Nubtwo", level = 5, dingedAt = time, classIndex = 1}
            local nub3 = {name = "Nubthree", level = 5, dingedAt = 0, classIndex = 2}
            local nub4 = {name = "Nubfour", level = 11, dingedAt = time, classIndex = 11}
            local nub5 = {name = "Nubfive", level = 1, dingedAt = time, classIndex = 1}

            local nub1str = SerPInfo(nub1)
            assert.same("0511Nubone1000000000", nub1str)
            assert.same(nub1, DeserPInfo(nub1str))

            local nub2str = SerPInfo(nub2)
            assert.same("051Nubtwo1000000000", nub2str)
            assert.same(nub2, DeserPInfo(nub2str))

            local nub3str = SerPInfo(nub3)
            assert.same("052Nubthree0", nub3str)
            assert.same(nub3, DeserPInfo(nub3str))

            local nub4str = SerPInfo(nub4)
            assert.same("1111Nubfour1000000000", nub4str)
            assert.same(nub4, DeserPInfo(nub4str))

            local nub5str = SerPInfo(nub5)
            assert.same("011Nubfive1000000000", nub5str)
            assert.same(nub5, DeserPInfo(nub5str))
        end)

        it("it more compact than AceSerializer", function()
            local nub1 = {name = "Nubone", level = 5, dingedAt = time, classIndex = 11}

            assert.same("0511Nubone1000000000", SerPInfo(nub1))
            assert.same(20, string.len(SerPInfo(nub1)))

            -- ^1^T^SclassIndex^N11^Slevel^N5^SdingedAt^N1000000000^Sname^SNubone^t^^
            assert.same(70, string.len(AceSerializer:Serialize(nub1)))

            assert.same("^1^T^N1^SNubone^N2^N5^N3^N1000000000^N4^N11^t^^",
                    AceSerializer:Serialize({nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex}))
            assert.same(47,
                    string.len(AceSerializer:Serialize({nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex})))
        end)
    end)

    describe("PlayerInfoBatch", function()
        it("serializes and deserializes", function()
            local nub1 = {name = "Nubone", level = 5, dingedAt = time + 10, classIndex = 11}
            local nub2 = {name = "Nubtwo", level = 5, dingedAt = time - 10, classIndex = 1}
            local nub3 = {name = "Nubthree", level = 5, dingedAt = time, classIndex = 2}
            local nub4 = {name = "Nubfour", level = 11, dingedAt = time , classIndex = 11}
            local nub5 = {name = "Nubfive", level = 1, dingedAt = time, classIndex = 1}
            local batch = {nub1, nub2, nub3, nub4, nub5}

            local batchstr = SerPInfoBatch(batch)
            assert.same("0999999990$0511Nubone20$051Nubtwo0$052Nubthree10$1111Nubfour10$011Nubfive10$",
                    batchstr)
            assert.same(batch, DeserPInfoBatch(batchstr))
        end)

        it("dingedAt offset 0", function()
            local nub1 = {name = "Nubone", level = 5, dingedAt = time, classIndex = 11}
            local nub2 = {name = "Nubtwo", level = 5, dingedAt = time, classIndex = 1}
            local nub3 = {name = "Nubthree", level = 5, dingedAt = 0, classIndex = 2}
            local nub4 = {name = "Nubfour", level = 11, dingedAt = time, classIndex = 11}
            local nub5 = {name = "Nubfive", level = 1, dingedAt = time, classIndex = 1}
            local batch = {nub1, nub2, nub3, nub4, nub5}

            local batchstr = SerPInfoBatch(batch)
            assert.same("0000000000$0511Nubone1000000000$051Nubtwo1000000000$052Nubthree0$1111Nubfour1000000000$011Nubfive1000000000$",
                    batchstr)
            assert.same(batch, DeserPInfoBatch(batchstr))
        end)

        it("it more compact than AceSerializer", function()
            local nub1 = {name = "Nubone", level = 5, dingedAt = time, classIndex = 11}
            local batch = {nub1, nub1, nub1, nub1, nub1}

            local batchstr = SerPInfoBatch(batch)
            assert.same("1000000000$0511Nubone0$0511Nubone0$0511Nubone0$0511Nubone0$0511Nubone0$",
                    batchstr)
            assert.same(71, string.len(batchstr))

            assert.same(238, string.len(
                    AceSerializer:Serialize({
                        {nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex},
                        {nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex},
                        {nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex},
                        {nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex},
                        {nub1.name, nub1.level, nub1.dingedAt, nub1.classIndex},
                    })
            ))
        end)
    end)
end)
