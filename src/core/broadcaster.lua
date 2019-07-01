-- Addon global
local TheClassicRace = _G.TheClassicRace

-- WoW API
local C_Timer, IsInGuild = _G.C_Timer, _G.IsInGuild

--[[
TheClassicRaceBroadcasterdoes a left-most binary search
to find the lower bound level in our /who query which gives > 0 results but < 50 (because we only get 50 from 1 query)
]]--
---@class TheClassicRaceBroadcaster
---@field Config TheClassicRaceConfig
---@field Core TheClassicRaceCore
---@field DB table<string, table>
---@field EventBus TheClassicRaceEventBus
local TheClassicRaceBroadcaster = {}
TheClassicRaceBroadcaster.__index = TheClassicRaceBroadcaster
TheClassicRace.Broadcaster = TheClassicRaceBroadcaster
setmetatable(TheClassicRaceBroadcaster, {
    __call = function(cls, ...)
        return cls.new(...)
    end,
})

function TheClassicRaceBroadcaster.new(Config, Core, DB, Network)
    local self = setmetatable({}, TheClassicRaceBroadcaster)

    self.Config = Config
    self.Core = Core
    self.DB = DB
    self.Network = Network

    self.timer = nil
    self.ticker = nil
    self.done = false

    return self
end

function TheClassicRaceBroadcaster:IsDone()
    return self.done
end

function TheClassicRaceBroadcaster:Start()
    if self.timer ~= nil or self.ticker ~= nil then
        return
    end

    -- to avoid everyone else who also received RequestUpdate from being in sync with us
    -- we'll add a random sleep offset
    -- @TODO: maybe we can do something better?
    --        like attempt to observe other broadcasters who are in sync with us offset to cover that
    local startOffset = math.random(1, 10)
    local tickOffset = math.random(0, 2)

    self.timer = C_Timer.NewTimer(startOffset, function()
        self.ticker = C_Timer.NewTicker(8 + tickOffset, function()
            self:Broadcast()
        end)
    end)
end

function TheClassicRaceBroadcaster:Broadcast()
    -- iterate over leaderboard descending
    for _, playerInfo in ipairs(self.DB.realm.leaderboard) do
        -- if a player hasn't been "observed" yet since our last received RequestUpdate
        -- then we can broadcast his info
        if playerInfo.observedAt < self.DB.realm.lastRequestUpdate then
            self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                    { playerInfo.name, playerInfo.level, playerInfo.dingedAt }, "CHANNEL")
            if IsInGuild() then
                self.Network:SendObject(self.Config.Network.Events.PlayerInfo,
                        { playerInfo.name, playerInfo.level, playerInfo.dingedAt }, "GUILD")
            end

            -- update observedAt
            playerInfo.observedAt = self.Core:Now()

            -- return out of this function completely
            return
        end
    end

    -- all players on our leaderboard were "observed" since our last received RequestUpdate
    -- this means we can stop broadcasting
    self.ticker:Cancel()
    self.done = true
end
