local Frame = {}
Frame.__index = Frame

setmetatable(Frame, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function Frame.new()
    local self = setmetatable({}, Frame)
    return self
end

function Frame:Hide()

end

function Frame:SetScript(type, callback)

end

function Frame:RegisterEvent(type, callback)

end

function Frame:UnregisterAllEvents()

end

function CreateFrame(type)
    if type ~= "Frame" then
        error("unsupported type arg to CreateFrame(" .. type .. ")")
    end

    return Frame()
end
