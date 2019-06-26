local TheClassicRace = _G.TheClassicRace

-- table helpers
TheClassicRace.table = {}

TheClassicRace.table.contains = function(list, value)
    for _, v in pairs(list) do
        if v == value then
            return true
        end
    end

    return false
end

TheClassicRace.table.filter = function(list, filterfn)
    local result = {}
    for k, v in ipairs(list) do
        if filterfn(v) then
            result[k] = v
        end
    end

    return result
end

TheClassicRace.table.reduce = function(table, fn, acc)
    for _, v in pairs(table) do
        if acc == nil then
            acc = v
        else
            acc = fn(v, acc)
        end
    end
    return acc
end

TheClassicRace.table.sum = function(table)
    return TheClassicRace.table.reduce(table, function(a, b)
        return a + b
    end)
end

TheClassicRace.table.cnt = function(table)
    return TheClassicRace.table.reduce(table, function(_, cnt)
        return cnt + 1
    end, 0)
end

TheClassicRace.table.avg = function(table)
    return TheClassicRace.table.sum(table) / TheClassicRace.table.cnt(table)
end

TheClassicRace.table.min = function(table)
    return TheClassicRace.table.reduce(table, function(a, b)
        if a > b then
            return b
        else
            return a
        end
    end)
end

TheClassicRace.table.max = function(table)
    return TheClassicRace.table.reduce(table, function(a, b)
        if a > b then
            return a
        else
            return b
        end
    end)
end

TheClassicRace.table.cntsumminmax = function(table, valuefn)
    local cnt = 0
    local minn = nil
    local maxx = nil
    local sum = nil

    for _, v in pairs(table) do
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
