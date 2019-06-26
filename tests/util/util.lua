-- load test base
TheClassicRace = require("testbase")

describe("RandomHash", function()
    it("gives random hashes", function()
        --[[
        this is a terrible way of testing randomness, but will have to do for now ...
        --]]
        local nhashes = 64
        local hashes = {}
        for i = 0, nhashes do
            hashes[i] = TheClassicRace.RandomHash(8)
        end

        for i = 0, nhashes do
            assert.equals(8, string.len(hashes[i]))

            for j = 0, nhashes do
                if i ~= j then
                    assert.not_equals(hashes[i], hashes[j])
                end
            end
        end
    end)
end)

describe("StringSplit", function()
    it("splits strings", function()
        assert.same({"oops", "I", "did", "it", "again"}, string.SplitString("oops:I:did:it:again", ":"))
        assert.same({"oops", "I", "did", "it", "again"}, string.SplitString("oops:I:did:it:again"))
        assert.same({"oops"}, string.SplitString("oops"))

        -- omits empty strings, as "expected"
        assert.same({"oops"}, string.SplitString("oops:"))
        assert.same({"oops", "again"}, string.SplitString("oops::again"))
    end)
end)
