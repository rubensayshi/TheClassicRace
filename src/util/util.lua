local TheClassicRace = _G.TheClassicRace

function TheClassicRace.IteratorToArray(iterator)
    local array = {}
    for v in iterator do
        array[#array + 1] = v
    end
    return array
end

function string:SplitString(seperator)
    return TheClassicRace.SplitString(self, seperator)
end

function TheClassicRace.SplitString(text, _sep)
    local sep, fields = _sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    text:gsub(pattern, function(c)
        fields[#fields + 1] = c
    end)
    return fields
end

local hash_chars = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E",
                     "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
                     "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
                     "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" }

function TheClassicRace.RandomHash(length)
    if (length == nil or length <= 0) then
        length = 32;
    end

    local holder = ""
    for _ = 1, length do
        local index = math.random(1, #hash_chars)
        holder = holder .. hash_chars[index]
    end

    return holder
end

function TheClassicRace.RecursivePrint(object, maxDepths, layer)
    layer = layer or 1
    if (type(object) == "table" and (maxDepths == nil or layer <= maxDepths)) then
        for key in pairs(object) do
            if (type(object[key]) == "table") then
                TheClassicRace.DebugPrint("Printing Table [" .. key .. "]")
                TheClassicRace.RecursivePrint(object[key], maxDepths, layer + 1)
            else
                TheClassicRace.DebugPrint(key .. ":" .. object[key])
            end
        end
    end
end

function TheClassicRace.ArrayContainsValue(array, val)
    for _, value in ipairs(array) do
        if value == val then
            return true
        end
    end
    return false
end
