_G.strmatch = string.match

local time = 1000000000

function _G.GetTime()
    return time
end

function _G.GetServerTime()
    return time
end

function _G.SetTime(_time)
    time = _time
end

function _G.hooksecurefunc()

end

_G.C_Timer = {
    now = 0,
    after = {},
}

function _G.C_Timer.Reset()
    _G.C_Timer.now = 0
    _G.C_Timer.after = {}
end

function _G.C_Timer.After(seconds, cb)
    table.insert(_G.C_Timer.after, {_G.C_Timer.now + seconds, cb})
end

function _G.C_Timer.Advance(seconds)
    _G.C_Timer.now = _G.C_Timer.now + seconds

    -- execute entries that passed
    for _, after in ipairs(_G.C_Timer.after) do
        if after[1] <= _G.C_Timer.now then
            after[2]()
        end
    end

    -- truncate any entries that passed
    _G.C_Timer.after = TheClassicRace.list.filter(_G.C_Timer.after, function(after)
        return after[1] > _G.C_Timer.now
    end)
end