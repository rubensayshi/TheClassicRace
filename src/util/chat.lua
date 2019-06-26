local TheClassicRace = _G.TheClassicRace

function TheClassicRace:Print(message)
    print("|cFFFFFFFF", message)
end

function TheClassicRace:SystemEventPrint(message)
    print(TheClassicRace.Colors.SYSTEM_EVENT_YELLOW, message)
end

function TheClassicRace:PPrint(message)
    print("|cFF7777FFTheClassicRace:|cFFFFFFFF", message)
end

function TheClassicRace:DebugPrint(message)
    if (self.Config.Debug == true) then
        print("|cFF7777FFTheClassicRace Debug:|cFFFFFFFF", message)
    end
end

function TheClassicRace:TracePrint(message)
    if (self.Config.Trace == true) then
        print("|cFF7777FFTheClassicRace Trace:|cFFFFFFFF", message)
    end
end

function TheClassicRace:DebugPrintTable(t)
    local function dump(o)
        if type(o) == "table" then
            local s = "{ "
            for k,v in pairs(o) do
                s = s .. "[" .. k .. "] = " .. dump(v) .. ", "
            end
            return s .. "} "
        else
            return tostring(o)
        end
    end

    if (self.Config.Debug == true) then
        print("|cFF7777FFTheClassicRace Debug:|cFFFFFFFF table...")
        print(dump(t))
    end
end

function TheClassicRace:PlayerChatLink(playerName)
    return TheClassicRace.Colors.SYSTEM_EVENT_YELLOW ..
        "|Hplayer:" .. playerName .. "|h[" .. playerName .. "]|h" ..
        TheClassicRace.Colors.WHITE
end