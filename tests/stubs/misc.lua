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