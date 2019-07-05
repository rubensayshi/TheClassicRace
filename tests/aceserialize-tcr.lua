-- load test base
local TheClassicRace = require("testbase")

-- libs
local LibStub = _G.LibStub
local Serializer = LibStub:GetLibrary("AceSerializer-3.0-TCR")

describe("AceSerializer-TCR", function()
    it("handle simple array", function()
        local payload = {"one", "two", "three", }
        local ser = Serializer:Serialize(payload)
        assert.same("^1^A^Sone^Stwo^Sthree^a^^", ser)

        local _, res = Serializer:Deserialize(ser)
        assert.same(payload, res)
    end)

    it("handle nested array", function()
    local payload = {{"one", "two"}, {11, 22}, {roobs = "three"}, }
        local ser = Serializer:Serialize(payload)
        assert.same("^1^A^A^Sone^Stwo^a^A^N11^N22^a^T^Sroobs^Sthree^t^a^^", ser)

        local _, res = Serializer:Deserialize(ser)
        assert.same(payload, res)
    end)

    it("still handles table", function()
        local payload = {one = "one", two = "two", three = "three", }

        -- this test isn't pretty but order of pairs() is non deterministic...
        for i = 0, 1000 do
            local ser = Serializer:Serialize(payload)

            local ok = "^1^T^Sone^Sone^Stwo^Stwo^Sthree^Sthree^t^^" == ser or
                       "^1^T^Sone^Sone^Sthree^Sthree^Stwo^Stwo^t^^" == ser or
                       "^1^T^Stwo^Stwo^Sthree^Sthree^Sone^Sone^t^^" == ser or
                       "^1^T^Stwo^Stwo^Sone^Sone^Sthree^Sthree^t^^" == ser or
                       "^1^T^Sthree^Sthree^Sone^Sone^Stwo^Stwo^t^^" == ser
            assert.is_true(ok)

            local _, res = Serializer:Deserialize(ser)
            assert.same(payload, res)
        end
    end)

    it("still handles table looks like array", function()
        local payload = {"one", "two"}
        payload[4] = "four"

        local ser = Serializer:Serialize(payload)
        assert.same("^1^T^N1^Sone^N2^Stwo^N4^Sfour^t^^", ser)

        local _, res = Serializer:Deserialize(ser)
        assert.same(payload, res)
    end)
end)
