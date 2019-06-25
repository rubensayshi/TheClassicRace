--[[
This file contains development-only things that aren't pretty but don't need to be ... xD

@TODO: when we make something to build releases it should make sure to omit this file
--]]
-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
TheClassicRace:tcr is our /tcr handler, it's temporary because everything should get a UI ...
--]]
function TheClassicRace:tcr(input)
    local action, arg1, arg2 = self:GetArgs(input, 3)

    --[[SCAN]]--
    if action == "scan" then
        self.Updater:StartScan()

    --[[RESET]]--
    elseif action == "reset" then
        self.DB:ResetDB()

    --[[REQUEST UPDATE]]--
    elseif action == "update" then
        self.Tracker:RequestUpdate()

    --[[LIST]]--
    elseif action == "list" then
        TheClassicRace:PPrint("highest level: " .. self.DB.realm.highestLevel)
        TheClassicRace:PPrint("lower bound threshold: " .. self.DB.realm.levelThreshold)

        for playerName, playerInfo in pairs(self.DB.realm.leaderboard) do
            print(" - " .. playerName .. " lvl" .. playerInfo.level)
        end

    --[[DING name level]]--
    elseif action == "ding" then
        TheClassicRace:DebugPrint("Forced Ding [" .. arg1 .. "] lvl" .. arg2 .. ".")
        self.EventBus:PublishEvent(self.Config.Events.PlayerInfo, {
            Name = arg1,
            Level = tonumber(arg2),
        })
    else
        self:PPrint("Unknown action: " .. tostring(action))
    end
end
