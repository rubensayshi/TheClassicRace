local TheClassicRace = _G.TheClassicRace

local function dumpTable(o)
    if type(o) == "table" then
        local s = "{ "
        for k,v in pairs(o) do
            s = s .. "[" .. k .. "] = " .. dumpTable(v) .. ", "
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

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
    if (self.Config.Debug == true) then
        print("|cFF7777FFTheClassicRace Debug:|cFFFFFFFF table...")
        print(dumpTable(t))
    end
end

function TheClassicRace:TracePrintTable(t)
    if (self.Config.Trace == true) then
        print("|cFF7777FFTheClassicRace Trace:|cFFFFFFFF table...")
        print(dumpTable(t))
    end
end

function TheClassicRace:PlayerChatLink(playerName, linkTitle, className)
    if linkTitle == nil then
        linkTitle = playerName
    end

    local color = TheClassicRace.Colors.SYSTEM_EVENT_YELLOW
    if className ~= nil and TheClassicRace.Colors[className] ~= nil then
        color = TheClassicRace.Colors[className]
    end

    return color ..
        "|Hplayer:" .. playerName .. "|h[" .. linkTitle .. "]|h" ..
        TheClassicRace.Colors.WHITE
end