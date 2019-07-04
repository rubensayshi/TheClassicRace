-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
TheClassicRaceScan executes several /who queries to find the highest level player online,
and to scan down from that player to fill the rest of the leaderboard

This is done with 3 steps:

First the "shortcut" scan, simply doing a /who for our previously known highest level, up to max level.
This should usually result in a direct hit, except when it's been a while since you were online.
When successful we skip the "binary search scan" and go straight to the "scan down" step.

If the "shortcut" scan did't succeed then we use our "binary search scan".
This does a left-most binary search between (min, max) so it's O(log n).

The last step is to fill the leaderboard with the runner ups,
because it's very likely there are a lot of runner ups we simply decrement down from the leader 1 by 1.
@TODO: on a very low pop server (like beta atm) scan down scans all the way down to 1 though the first time ...
@TODO: we should apply binary search to downwards search as well!
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

function TheClassicRaceScan.new(Core, DB, EventBus, who, min, prevhighestlvl, max)
    local self = setmetatable({}, TheClassicRaceScan)

    self.Core = Core
    self.DB = DB
    self.EventBus = EventBus

    --[[
    self.who contains our /who querier, it takes (min, max, callback) as params
    where min and max are inclusive.

    the callback receives (query, result, complete) as params
    where query is the query we used (min .. "-" .. max)
    result is a list of the players found
    and complete is a boolean which is false when there's more players that meet our query than possible to return
    this is a very important param since /who queries are limited to 48 results and we need to work around this
    ]]--
    self.who = who

    self.min = min
    self.prevhighestlvl = prevhighestlvl
    self.max = max

    -- this is scan state that is later set and used
    self.m = nil
    self.downmax = nil
    self.downm = nil

    -- this is general state
    self.done = false
    self.started = false
    self.complete = false

    return self
end

function TheClassicRaceScan:IsDone()
    return self.done, self.complete
end

function TheClassicRaceScan:FinishScan()
    self.done = true

    -- we've reached the end of race if the last result was complete=false (meaning there were more than 50 results)
    -- and if we never moved the right pointer down (meaning we never had 0 results)
    local endofrace = not self.complete and self.right >= self.max

    self.EventBus:PublishEvent(TheClassicRace.Config.Events.ScanFinished, endofrace)
end

function TheClassicRaceScan:Start()
    if self.started then
        return
    end

    self.started = true

    -- we start with a shortcut to search for (min, max)
    -- and the shortcut scan determines what the next step should be
    self:ShortcutScan()
end

function TheClassicRaceScan:CleanResult(result)
    -- filter out nils, seems to be a possibility ...
    -- filter out other servers ...
    return TheClassicRace.list.filter(result, function (player)
        if player ~= nil and player.Name ~= nil and player.Level ~= nil then
            local _, realm = self.Core:SplitFullPlayer(player.Name)

            return realm == nil or self.Core:IsMyRealm(realm)
        else
            return false
        end
    end)
end

function TheClassicRaceScan:ShortcutScan()
    local function cb(query, result, complete)
        result = self:CleanResult(result)

        TheClassicRace:DebugPrint("who '" .. query .. "' result: " .. #result .. ", complete: " .. tostring(complete))

        -- if our shortcut scan produced results and was complete then we can use it
        -- otherwise we need to do a binary search scan
        if complete and #result > 0 then
            for _, player in ipairs(result) do
                TheClassicRace:DebugPrint(" - " .. player.Name .. " lvl" .. player.Level)
            end

            -- stash complete for when we broadcast ScanFinished event
            self.complete = complete

            -- move to the ScanDown step
            self:ScanDown()
        else
            -- move to the binary search scan step
            self:BinarySearchScan()
        end
    end

    self.who(self.prevhighestlvl, self.max, cb)
end

function TheClassicRaceScan:BinarySearchScan()
    -- binary search state
    self.left = self.min
    self.right = self.max + 1 -- +1 to make it inclusive

    self:BinarySearchNext()
end

function TheClassicRaceScan:BinarySearchNext()
    self.m = math.floor((self.left + self.right) / 2)

    local function cb(query, result, complete)
        result = self:CleanResult(result)

        TheClassicRace:DebugPrint("who '" .. query .. "' result: " .. #result .. ", complete: " .. tostring(complete))

        -- once more=false we can stop with the binary search scan
        local more = self:BinarySearchHandleResult(query, result, complete)
        if not more then
            -- stash complete for when we broadcast ScanFinished event
            self.complete = complete

            -- if our binary search scan produced results then we can follow up with a scan down
            -- otherwise we can finish the scan here
            if complete and #result > 0 then
                for _, player in ipairs(result) do
                    TheClassicRace:DebugPrint(" - " .. player.Name .. " lvl" .. player.Level)
                end

                -- move to the ScanDown step
                self:ScanDown()
            else
                -- finish up our scan
                self:FinishScan()
            end
        end
    end

    self.who(self.m, self.max, cb)
end

function TheClassicRaceScan:BinarySearchHandleResult(_, result, complete)
    -- if we have 0 results then we need to decrease lower bound
    if #result == 0 then
        -- value > target -> right = m
        self.right = self.m

    -- if we have > 0 results and not more than we can query in 1 /who then we are done
    elseif complete then
        -- value == target -> right = m
        -- we can exit early here because we don't need to find the exact m
        return false

    -- if we have too many results for 1 /who query then we need to increase lower bound to refine the result
    else
        -- value < target -> left = m + 1

        -- reached max level, we can exit regardless of complete
        if self.m == self.max then
            return false
        end

        self.left = self.m + 1
    end

    -- do next scan
    if self.left < self.right then
        self:BinarySearchNext()
        return true
    else
        return false
    end
end

function TheClassicRaceScan:ScanDown()
    -- scan down search state
    if self.m ~= nil then
        self.downmax = self.m - 1
    else
        self.downmax = self.prevhighestlvl - 1
    end
    self.downm = self.downmax

    if self.downm < self.min then
        self:FinishScan()
        return
    else
        self:ScanDownNext()
    end
end

function TheClassicRaceScan:ScanDownNext()
    local function cb(query, result, complete)
        result = self:CleanResult(result)

        TheClassicRace:DebugPrint("who '" .. query .. "' result: " .. #result .. ", complete: " .. tostring(complete))

        local more = self:ScanDownHandleResult(query, result, complete)

        if not more then
            self:FinishScan()

            if complete and #result > 0 then
                for _, player in ipairs(result) do
                    TheClassicRace:DebugPrint(" - " .. player.Name .. " lvl" .. player.Level)
                end
            end
        end
    end

    self.who(self.downm, self.downmax, cb)
end

function TheClassicRaceScan:ScanDownHandleResult(_, _, complete)
    -- we've queried too much, no point in continueing
    if not complete then
        return false
    end

    -- decrease our lower bound to capture more results
    self.downm = self.downm - 1

    -- adhere to our lower level bound
    if self.downm < self.min then
        return false
    end

    -- do next scan
    self:ScanDownNext()

    return true
end
