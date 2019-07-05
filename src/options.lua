local TheClassicRace = _G.TheClassicRace

-- Libs
local LibStub = _G.LibStub
local LibDBIcon = LibStub("LibDBIcon-1.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- colors
local WHITE = TheClassicRace.Colors.WHITE
local BROWN = TheClassicRace.Colors.BROWN

function TheClassicRace:RegisterOptions()
    local _self = self

    local configOptions = {
        type = "group",
        args = {
            enable = {
                name = "Show Minimap Icon",
                desc = "Enables / disables the minimap icon",
                type = "toggle",
                set = function(_, val)
                    _self.DB.profile.options.minimap.hide = not val
                    if val then
                        LibDBIcon:Show(TheClassicRace.Config.LDB)
                    else
                        LibDBIcon:Hide(TheClassicRace.Config.LDB)
                    end
                end,
                get = function() return not _self.DB.profile.options.minimap.hide end
            },
            moreoptions = {
                name = "Options",
                type = "group",
                args = {
                    leaderboardSize = {
                        order = 1,
                        name = "Number of players to track",
                        desc = "Limit how many players to track for leaderboard and chat notifications",
                        descStyle = "inline",
                        width = "full",
                        type = "range",
                        step = 1,
                        min = 1,
                        max = TheClassicRace.Config.MaxLeaderboardSize,
                        set = function(_, val)
                            local decreased = val < _self.DB.profile.options.leaderboardSize
                            _self.DB.profile.options.leaderboardSize = val

                            -- broadcast event when size decreased
                            if decreased then
                                _self.EventBus:PublishEvent(TheClassicRace.Config.Events.LeaderboardSizeDecreased)
                            end
                        end,
                        get = function() return _self.DB.profile.options.leaderboardSize end
                    },
                    enableNotifications = {
                        order = 2,
                        name = "Enable Notifications",
                        desc = "Enables / disables the notifications in your chat window",
                        descStyle = "inline",
                        width = "full",
                        type = "toggle",
                        set = function(_, val) _self.DB.profile.options.notifications = val end,
                        get = function() return _self.DB.profile.options.notifications end
                    },
                    enableNetworking = {
                        order = 3,
                        name = "Enable Sharing / Receiving Data",
                        desc = "Enables / disables the sharing of data through addon channels",
                        descStyle = "inline",
                        width = "full",
                        type = "toggle",
                        set = function(_, val) _self.DB.profile.options.networking = val end,
                        get = function() return _self.DB.profile.options.networking end
                    },
                    dontBumpScan = {
                        order = 4,
                        name = "Always /who query",
                        desc = "Do a /who scan every 60s even when data was synced from another player",
                        descStyle = "inline",
                        width = "full",
                        type = "toggle",
                        set = function(_, val) _self.DB.profile.options.dontbump = val end,
                        get = function() return _self.DB.profile.options.dontbump end
                    },
                    reset = {
                        order = 5,
                        name = "Reset Data",
                        type = "execute",
                        func = function()
                            _self.DB:ResetDB()
                            _self.StatusFrame:Refresh()
                        end,
                    },
                }
            }
        }
    }

    AceConfig:RegisterOptionsTable(TheClassicRace.Config.AceConfig, configOptions, {"tcropts"})
    AceConfigDialog:AddToBlizOptions(TheClassicRace.Config.AceConfig, TheClassicRace.Config.AceConfig)

    local ldb = LibDataBroker:NewDataObject(TheClassicRace.Config.LDB, {
        type = "data source",
        text = "The Classic Race",
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
        OnClick = function(_, ...) _self:MinimapIconClick(...) end
    })
    LibDBIcon:Register(TheClassicRace.Config.LDB, ldb, self.DB.profile.options.minimap)

    local hint = WHITE .. "The Classic Race\n" ..
                 BROWN .. "Click|r to show the leaderboard. " ..
                 BROWN .. "Right-Click|r to open options dialog."
    function ldb.OnTooltipShow(tt)
        tt:AddLine(hint, 0.2, 1, 0.2, 1)
    end

end

function TheClassicRace:MinimapIconClick(button)
    if button == "RightButton" then
        AceConfigDialog:Open(TheClassicRace.Config.AceConfig)
    else
        self.StatusFrame:Show()
    end
end
