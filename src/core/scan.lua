-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
TheClassicRaceScan does a left-most binary search
to find the lower bound level in our /who query which gives > 0 results but < 50 (because we only get 50 from 1 query)
]]--
---@class TheClassicRaceScan
---@field DB table<string, table>
---@field Core TheClassicRaceCore
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceScan = {}
TheClassicRaceScan.__index = TheClassicRaceScan
TheClassicRace.Scan = TheClassicRaceScan
setmetatable(TheClassicRaceScan, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceScan.new(Core, DB, EventBus, who, min, max)
    local self = setmetatable({}, TheClassicRaceScan)

    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus
    self.who = who

    self.min = min
    self.max = max

    self.done = false
    self.started = false

    return self
end

function TheClassicRaceScan:SetMin(min)
    -- normally we'd err but can't in WoW addons?
    if self.started then
        return
    end

    self.min = min
end

function TheClassicRaceScan:IsDone()
    return self.done
end

function TheClassicRaceScan:HandleResult(_, result, complete)
    -- if we have 0 results then we need to decrease lower bound
    if #result == 0 then
        -- value > target -> right = m
        self.right = self.m

    -- if we have > 0 results and not more than we can query in 1 /who then we are done
    elseif complete then
        -- value == target -> right = m
        -- we can exit early here because we don't need to find the exact m
        self.done = true
        return

    -- if we have too many results for 1 /who query then we need to increase lower bound to refine the result
    else
        -- value < target -> left = m + 1

        -- too many people at highest level, we can exit early
        if self.m == self.max then
            self.done = true
            return
        end

        self.left = self.m + 1
    end

    -- do next scan
    self:Next()
end

function TheClassicRaceScan:Start()
    if self.started then
        return
    end

    self.started = true

    -- instead of starting with our binary search we start with a shortcut to search for (min, max)
    -- and then lead into the binary search
    self:Shortcut()
end

function TheClassicRaceScan:Shortcut()
    local function cb(query, result, complete)
        TheClassicRace:DebugPrint("who '" .. query .. "' result: " .. #result .. ", complete: " .. tostring(complete))

        if complete and #result > 0 then
            self.done = true

            for _, player in ipairs(result) do
                TheClassicRace:DebugPrint(" - " .. player.Name .. " lvl" .. player.Level)
            end
        else
            self:BinarySearch()
        end
    end

    self.who(self.min, self.max, cb)
end

function TheClassicRaceScan:BinarySearch()
    -- binary search state
    self.left = self.min
    self.right = self.max

    self:Next()
end

function TheClassicRaceScan:Next()
    self.m = math.floor((self.left + self.right) / 2)

    local function cb(query, result, complete)
        TheClassicRace:DebugPrint("who '" .. query .. "' result: " .. #result .. ", complete: " .. tostring(complete))

        if complete and #result > 0 then
            for _, player in ipairs(result) do
                TheClassicRace:DebugPrint(" - " .. player.Name .. " lvl" .. player.Level)
            end
        end

        self:HandleResult(query, result, complete)
    end

    self.who(self.m, self.max, cb)
end