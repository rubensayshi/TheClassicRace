local assert = require("luassert.assert")

--[[
LibWhoMock is a mock for LibWho
It has an :ExpectWho method to construct a list of expected calls and their return values
And an :Assert to assert that all expected calls were consumed
]]--
---@class LibWhoMock
local LibWhoMock = {}
LibWhoMock.__index = LibWhoMock
setmetatable(LibWhoMock, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function LibWhoMock.new()
    local self = setmetatable({}, LibWhoMock)

    self.expectedCalls = {}

    return self
end

function LibWhoMock:Who(min, max, cb)
    print("LibWhoMock:Who(" .. min .. ", " .. max .. ")")
    assert.is_true(#self.expectedCalls > 0, "no expected calls remaining")
    local expectedCall = table.remove(self.expectedCalls, 1)

    assert.equals(expectedCall.min, min, "call to who() with unexpected min")
    assert.equals(expectedCall.max, max, "call to who() with unexpected max")

    cb(min .. "-" .. max, expectedCall.result, expectedCall.complete)
end

function LibWhoMock:ExpectWho(min, max, complete, result)
    table.insert(self.expectedCalls, {min = min, max = max, complete = complete, result = result})
end

function LibWhoMock:Assert()
    assert.equals(#self.expectedCalls, 0, "not all expected calls consumed")
end

return LibWhoMock
