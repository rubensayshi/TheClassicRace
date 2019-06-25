local TheClassicRace = _G.TheClassicRace

-- list helpers
TheClassicRace.list = {}

TheClassicRace.list.contains = function(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end

    return false
end

TheClassicRace.list.filter = function(list, filterfn)
    local result = {}
    for _, v in ipairs(list) do
        if filterfn(v) then
            table.insert(result, v)
        end
    end

    return result
end

TheClassicRace.list.reduce = function(list, fn, acc)
    for _, v in ipairs(list) do
        if acc == nil then
            acc = v
        else
            acc = fn(v, acc)
        end
    end
    return acc
end

TheClassicRace.list.sum = function(list)
    return TheClassicRace.list.reduce(list, function(a, b)
        return a + b
    end)
end

TheClassicRace.list.cnt = function(list)
    return TheClassicRace.list.reduce(list, function(_, cnt)
        return cnt + 1
    end, 0)
end

TheClassicRace.list.avg = function(list)
    return TheClassicRace.list.sum(list) / TheClassicRace.list.cnt(list)
end

TheClassicRace.list.min = function(list)
    return TheClassicRace.list.reduce(list, function(a, b)
        if a > b then
            return b
        else
            return a
        end
    end)
end

TheClassicRace.list.max = function(list)
    return TheClassicRace.list.reduce(list, function(a, b)
        if a > b then
            return a
        else
            return b
        end
    end)
end

TheClassicRace.list.cntsumminmax = function(list, valuefn)
    local cnt = 0
    local minn = nil
    local maxx = nil
    local sum = nil

    for _, v in pairs(list) do
        if valuefn ~= nil then
            v = valuefn(v)
        end

        cnt = cnt + 1

        if sum == nil then
            sum = v
        else
            sum = sum + v
        end

        if maxx == nil or v > maxx then
            maxx = v
        end
        if minn == nil or v < minn then
            minn = v
        end
    end

    return cnt, sum, minn, maxx
end
