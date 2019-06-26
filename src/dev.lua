--[[
This file contains development-only things that aren't pretty but don't need to be ... xD
--]]
-- Addon global
local TheClassicRace = _G.TheClassicRace

--[[
The /tcr handler, overwrites with a more advanced development mode /tcr
--]]
function TheClassicRace:slashtcr(input)
    local action, arg1, arg2 = self:GetArgs(input, 3)

    --[[SCAN]]--
    if action == "scan" then
        self.Updater:StartScan()

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
        self.Tracker:RequestUpdate()

    --[[LIST]]--
    elseif action == "list" then
        TheClassicRace:PPrint("highest level: " .. self.DB.realm.highestLevel)
        TheClassicRace:PPrint("lower bound threshold: " .. self.DB.realm.levelThreshold)

        for rank, playerInfo in ipairs(self.DB.realm.leaderboard) do
            print(" - #" .. rank .. " " .. playerInfo.name .. " lvl" .. playerInfo.level)
        end

    --[[DING name level]]--
    elseif action == "ding" then
        TheClassicRace:DebugPrint("Forced Ding [" .. arg1 .. "] lvl" .. arg2 .. ".")
        self.EventBus:PublishEvent(self.Config.Events.SlashWhoResult, {
            name = arg1,
            level = tonumber(arg2),
        })
    else
        self:PPrint("Unknown action: " .. tostring(action))
    end
end
