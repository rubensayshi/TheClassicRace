local TheClassicRace = _G.TheClassicRace

-- Libs
local LibStub = _G.LibStub
local LibDBIcon = LibStub("LibDBIcon-1.0")
local LibDataBroker = LibStub("LibDataBroker-1.1")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

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
                    enableNotifications = {
                        name = "Enable Notifications",
                        desc = "Enables / disables the notifications in your chat window",
                        descStyle = "inline",
                        width = "full",
                        type = "toggle",
                        set = function(_, val) _self.DB.profile.options.notifications = val end,
                        get = function() return _self.DB.profile.options.notifications end
                    },
                    enableNetworking = {
                        name = "Enable Sharing / Receiving Data",
                        desc = "Enables / disables the sharing of data through addon channels",
                        descStyle = "inline",
                        width = "full",
                        type = "toggle",
                        set = function(_, val) _self.DB.profile.options.networking = val end,
                        get = function() return _self.DB.profile.options.networking end
                    },
                    reset = {
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
        icon = "Interface\\Icons\\inv_misc_groupneedmore",
        OnClick = function(_, ...) _self:MinimapIconClick(...) end
    })
    LibDBIcon:Register(TheClassicRace.Config.LDB, ldb, self.DB.profile.options.minimap)
end

function TheClassicRace:MinimapIconClick(button)
    if button == "RightButton" then
        AceConfigDialog:Open(TheClassicRace.Config.AceConfig)
    else
        self.StatusFrame:Show()
    end
end
