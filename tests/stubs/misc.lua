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

_G.C_Timer = {}

function _G.C_Timer.NewTicker()
    local ticker = {}
    function ticker:Cancel() end

    return ticker
end

function _G.C_Timer.NewTimer()
    local timer = {}
    function timer:Cancel() end

    return timer
end