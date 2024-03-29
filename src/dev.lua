﻿--[[
This file contains development-only things that aren't pretty but don't need to be ... xD
--]]
-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
The /tcr handler, overwrites with a more advanced development mode /tcr
--]]
function TheClassicRace:slashtcr(input)
    local action, arg1, arg2, arg3 = self:GetArgs(input, 4)

    --[[SCAN]]--
    if action == "scan" then
        self.scanner:StartScan()

    --[[CLASS SYNC]]--
    elseif action == "classscan" then
        self.classScanner:StartScan()

    --[[RESET]]--
    elseif action == "reset" then
        self.DB:ResetDB()

    --[[SHOW FRAME]]--
    elseif action == "show" then
        self.StatusFrame:Show()

    --[[UPDATE FRAME]]--
    elseif action == "render" then
        self.StatusFrame:Render()

    --[[REQUEST UPDATE]]--
    elseif action == "update" then
        self.Sync:InitSync()

    --[[WHOAMI]]--
    elseif action == "whoami" then
        self.Core:InitMe(arg1, self.Core:MyRealm())

    --[[DING name level]]--
    elseif action == "ding" then
        TheClassicRace:DebugPrint("Forced Ding [" .. arg1 .. "] lvl" .. arg2 .. ".")
        self.EventBus:PublishEvent(self.Config.Events.SlashWhoResult, {{
            name = arg1,
            level = tonumber(arg2),
            class = arg3 or "DRUID",
        }})
    else
        self:PPrint("Unknown action: " .. tostring(action))
    end
end
