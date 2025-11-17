local AS = AddonSelectorGlobal
local constants = AS.constants
local utility = AS.utility

local ADDON_NAME = AS.name
local addonNamePrefix = AS.addonNamePrefix

local booleanToOnOff = constants.strings.booleanToOnOff

--ZOs reference variables
local tos = tostring
local strgma = string.gmatch
local strlow = string.lower
local strfor = string.format

local EM = EVENT_MANAGER

local openGameMenuAndAddOnsAndThenSearch = AS.OpenGameMenuAndAddOnsAndThenSearch
local updateDDL = utility.updateDDL
local areAllAddonsEnabled = utility.areAllAddonsEnabled

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText

local skipLoadAddonPackStr = AddonSelector_GetLocalizedText("skipLoadAddonPack")

--======================================================================================================================
-- SlashCommands
--======================================================================================================================
local function searchAddOnSlashCommandHandlder(args)
    if not args or args == "" then
        AS.showAddOnsList()
    else
        --Parse the arguments string
        local options = {}
        --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
        for param in strgma(args, "([^%s]+)%s*") do
            if (param ~= nil and param ~= "") then
                options[#options+1] = strlow(param)
            end
        end
        if options and options[1] then
            openGameMenuAndAddOnsAndThenSearch(tos(options[1]))
        end
    end
    AS.flags.addonListWasOpenedByAddonSelector = false
end

local function loadAddOnPackSlashCommandHandler(args, noReloadUI)
    AS.OpenGameMenuAndAddOnsAndThenLoadPack(args, nil, noReloadUI, nil)
end


local function skipLoadAddonPackOnLogoutToggle(args)
    if args == nil or args == "" then
        AS.acwsvChar.skipLoadAddonPackOnLogout = not AS.acwsvChar.skipLoadAddonPackOnLogout
        updateDDL()
    else
        if args == "0" or args == "false" or args == "off" then
            AS.acwsvChar.skipLoadAddonPackOnLogout = false
            updateDDL()
        elseif args == "1" or args == "true" or args == "on" then
            AS.acwsvChar.skipLoadAddonPackOnLogout = true
            updateDDL()
        end
    end
    local currentValue = AS.acwsvChar.skipLoadAddonPackOnLogout
    d(strfor(addonNamePrefix .. skipLoadAddonPackStr, tos(booleanToOnOff[currentValue])))
end

local function disableAllAddonsAndReload()
    AddonSelector_DisableAllAddonsAndReloadUI()
end

--Slash commands
local function registerSlashCommands()
    SLASH_COMMANDS["/rl"]               = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/rlui"]             = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/reload"]           = AddonSelector_ReloadTheUI
    if SLASH_COMMANDS["/addons"] == nil then
        SLASH_COMMANDS["/addons"]       = searchAddOnSlashCommandHandlder
    end
    if SLASH_COMMANDS["/as"] == nil then
        SLASH_COMMANDS["/as"]           = searchAddOnSlashCommandHandlder
    end
    SLASH_COMMANDS["/addonsearch"]      = searchAddOnSlashCommandHandlder
    SLASH_COMMANDS["/addonselector"]    = searchAddOnSlashCommandHandlder
    if SLASH_COMMANDS["/asl"] == nil then
        SLASH_COMMANDS["/asl"]          = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    end
    SLASH_COMMANDS["/addonload"]        = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    SLASH_COMMANDS["/loadpack"]         = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    if SLASH_COMMANDS["/aslrl"] == nil then
        SLASH_COMMANDS["/aslrl"]          = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    end
    SLASH_COMMANDS["/addonloadrl"]        = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    SLASH_COMMANDS["/loadpackrl"]         = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    if SLASH_COMMANDS["/aslskip"] == nil then
        SLASH_COMMANDS["/aslskip"]      = skipLoadAddonPackOnLogoutToggle
    end
    if SLASH_COMMANDS["/asls"] == nil then
        SLASH_COMMANDS["/asls"]         = skipLoadAddonPackOnLogoutToggle
    end
    SLASH_COMMANDS["/loadpackskip"]     = skipLoadAddonPackOnLogoutToggle


    SLASH_COMMANDS["/asap"]             = AddonSelector_ShowActivePackInChat

    SLASH_COMMANDS["/asnone"]           = disableAllAddonsAndReload
    SLASH_COMMANDS["/addonselectornone"]= disableAllAddonsAndReload

    if LibAddonMenu2 ~= nil then
        SLASH_COMMANDS["/addonsettings"] =  AS.ShowLAMAddonSettings
        SLASH_COMMANDS["/lam"] =            AS.ShowLAMAddonSettings
    end
end
AS.RegisterSlashCommands = registerSlashCommands
