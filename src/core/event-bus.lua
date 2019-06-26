local TheClassicRace = _G.TheClassicRace

---@class TheClassicRaceEventBus
local TheClassicRaceEventBus = {}
TheClassicRaceEventBus.__index = TheClassicRaceEventBus

TheClassicRace.EventBus = TheClassicRaceEventBus

setmetatable(TheClassicRaceEventBus, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceEventBus.new()
    local self = setmetatable({}, TheClassicRaceEventBus)
    self.Listeners = {}
    return self
end

function TheClassicRaceEventBus:RegisterCallback(event, object, callback)
    if (self.Listeners[event] == nil) then
        self.Listeners[event] = {}
    end
    table.insert(self.Listeners[event], { Object = object, Callback = callback })
end

function TheClassicRaceEventBus:PublishEvent(event, ...)
    TheClassicRace:TracePrint("Event published: " .. event)
    if (self.Listeners[event] ~= nil) then
        for key in pairs(self.Listeners[event]) do
            self.Listeners[event][key].Callback(self.Listeners[event][key].Object, ...)
        end
    end
end
