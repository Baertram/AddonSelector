--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--              DO NOT CHANGE THIS FILE!
--    DO NOT COPY THIS FILE FOR YOUR LANGUAGE TRANSLATIONS!
--          Copy any other file like de.lua or fr.lua
--        and just check which translation strings below
--           in en.lua's table langArray are missing
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--Define the global variable
AddonSelectorGlobal = AddonSelectorGlobal or {}

local AS = AddonSelectorGlobal
AS.name = "AddonSelector"
local ADDON_NAME = AS.name
local addonNamePrefix = "["..ADDON_NAME.."]"
AS.addonNamePrefix = addonNamePrefix
-->Only name and prefix are added here. Further values are added at Constants.lua

--Create constants table
AS.constants = {}
local constants = AS.constants
constants.textures = {}
local textures = constants.textures

local keybindTexture = "|t80.000000%:80.000000%:/esoui/art/buttons/keyboard/nav_pc_arrowkeys_down.dds|t"
textures.keybind = keybindTexture
textures.removepoints = "/esoui/art/progression/removepoints_up.dds"
textures.overwrite = "/esoui/art/buttons/edit_save_over.dds"




--Variables for translations
local addonSelectorStrPrefix = "SI_AS_"
constants.addonSelectorStrPrefix = addonSelectorStrPrefix
local stringConstants


--Helper functions for translations
--Get localized texts
function AddonSelector_GetLocalizedText(textToFind)
    stringConstants = stringConstants or AS.constants.strings
    if stringConstants ~= nil then
        local retStr = stringConstants[textToFind]
        if retStr ~= nil and retStr ~= "" then
            return retStr
        end
    end
    return GetString(_G[addonSelectorStrPrefix .. textToFind])
end


--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--              DO NOT CHANGE THIS FILE!
--    DO NOT COPY THIS FILE FOR YOUR LANGUAGE TRANSLATIONS!
--          Copy any other file like de.lua or fr.lua
--        and just check which translation strings below
--           in en.lua's table langArray are missing
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

------------------------------------------------------------------------------------------------------------------------
-- En Strings for translations
------------------------------------------------------------------------------------------------------------------------
--The strings
local langArray = {
    ["packName"]			= "Pack name:",
    ["selectPack"]			= "Select",
    ["ERRORpackMissing"] 	= "ADDON SELECTOR: Pack name missing.",
    ["autoReloadUIHint"]	= "Auto-Reload UI on pack selection.",
    ["autoReloadUIHintTooltip"] = "Auto-Reload UI: When ON this will prevent editing and deleting addon packs. You will need to turn it off to edit or delete packs!",
    ["saveButton"]			= "Save",
    ["savePackTitle"]        = "Overwrite pack?",
    ["savePackBody"]        = "Overwrite existing pack %s?",
    ["deleteButton"]		= "Delete",
    ["deletePackTitle"]     = zo_iconTextFormatNoSpace(textures.removepoints, 24, 24, "Delete: "),
    ["deletePackAlert"]     = "ADDON SELECTOR: You must select a pack to delete.",
    ["deletePackError"]     = "ADDON SELECTOR: Pack delete error\n%s.",
    ["deletePackBody"]      = "Really delete?\n%s",
    ["DeselectAllAddons"]   = "Deselect all",
    ["SelectAllAddons"]     = "Select all",
    ["DeselectAllLibraries"]= "Deselect all libaries",
    ["SelectAllLibraries"]  = "Select all libaries",
    ["ScrollToAddons"]       = "^ AddOns    ^",
    ["ScrollToLibraries"]    = "v Libraries v",
    ["SelectAllAddonsSaved"] = "Select saved",
    ["AddonSearch"]          = "Search:",
    ["selectedPackName"]     = "Selected (%s): ",
    ["LibDialogMissing"]     = "Library \'LibDialog\' is missing! This addon will not work without it!",
    ["ShowActivePack"]      = "Show active pack",
    ["ShowSubMenuAtGlobalPacks"] = "Show submenu at global packs",
    ["ShowSettings"]        = "Show \'"..ADDON_NAME.."\' settings",
    ["ShowGlobalPacks"]     = "Show global saved packs",
    ["GlobalPackSettings"] = "Global pack settings",
    ["CharacterNameSettings"] = "Character name settings",
    ["SaveGroupedByCharacterName"] = "Save packs by character name",
    ["ShowGroupedByCharacterName"] = "Show packs of character names",
    ["packCharName"]        = "Character of pack",
    ["packGlobal"]          = "Global",
    ["searchExcludeFilename"] = "Exclude filename",
    ["searchSaveHistory"] = "Save history of search terms",
    ["searchClearHistory"] = "Clear history",
    ["UndoLastMassMarking"] = "< Undo last markings",
    ["ClearLastMassMarking"] = "Clear marking backup",
    ["LastPackLoaded"] = "Last loaded:",
    ["addonCategories"] = "Addon categories",
    ["noCategory"]      = "-No category-",
    ["ToggleAddonState"] = "AddOn: On/Off",
    ["searchInstructions"] = "The cursor is in the searchbox. Type to start new search, press return key to jump to next found addon. Press the ESCAPE key to leave the searchbox again.",
    ["foundSearch"]         = "[Found]",
    ["foundSearchLast"]     = "[Found last entry]",
    ["currentText"]         = "Current: ",
    ["enableText"]          = "Enable",
    ["disableText"]         = "Disable",
    ["enDisableCurrentStateTemplate"] = "%s all addons. Current state   -   %s",
    ["stateText"]           = "State",
    ["newStateText"]        = "New state",
    ["libraryText"]         = "Library",
    ["openDropdownStr"]	    = "Click to open the dropdown box",
    ["openedStr"]           = "Opened",
    ["closedStr"]           = "Closed",
    ["chosenStr"]           = "Chosen",
    ["addPackTooltip"]      = "Add tooltip to pack in dropdown box",
    ["accountWide"]         = "Account-wide addOn pack",
    ["accountWides"]         = "Account-wide addOn packs",
    ["characterWide"]       = "Charakter specific addOn packs",
    ["characterWides"]      = "Charakter specific addOn pack",
    ["settingPattern"]       = "[Setting] %s",
    ["searchHistoryPattern"] = "[Search history] %s",
    ["submenu"]              = "Submenu",
    ["entryMouseEnter"]      = "Entry below mouse",
    ["entrySelected"]        = "Entry was selected",
    ["entries"]              = "entries",
    ["checkBox"]             = "Checkbox",
    ["enabledAddonsInPack"]  = "Enabled AddOns in pack ",
    ["showPacksAddonList"]   = "Show pack's AddOn list submenu",
    ["addonsInPack"]         = "AddOns in pack %q",
    ["librariesInPack"]      = "Libraries in pack %q",
    ["showSearchFilterAtPacksList"] = "Show search at the pack list",
    ["OverwriteSavePack"]    = zo_iconTextFormatNoSpace(textures.overwrite, 24, 24, "%s overwrite (with currently selected)"),
    ["deleteWholeCharacterPacksTitle"] = "Delete all packs of character",
    ["deleteWholeCharacterPacksQuestion"] = "Really delete ALL packs?",
    ["otherAccount"] = "|cf9a602(Other @)|r",
    ["ShowPacksOfOtherAccountsChars"] = "Show packs of other @accounts",
    ["changedAddonPack"] = "Changed addon pack %q, %s - Count: %s",
    ["saveChangesNow"] = "--- Save changes now ---",
    ["packNameLoadFound"] = "Packname was loaded: %q, globalOrCharacterName: %s",
    ["packNameLoadNotFound"] = "Packname was not found: %q, globalOrCharacterName: %s",
    ["packNameLoadAtLogoutFound"] = "Packname loaded at Logout: %q, globalOrCharacterName: %s [Logged in character: %q]",
    ["LoadPackByKeybind1"] = "Load pack 1",
    ["LoadPackByKeybind2"] = "Load pack 2",
    ["LoadPackByKeybind3"] = "Load pack 3",
    ["LoadPackByKeybind4"] = "Load pack 4",
    ["LoadPackByKeybind5"] = "Load pack 5",
    ["addPackToKeybind"] =      "|c0FF000+ Add|r pack to keybind %s",
    ["removePackFromKeybind"] = "|cFF0000- Remove|r pack from keybind %s",
    ["loadOnLogoutOrQuit"] = "Load automatically at logout/quit",
    ["skipLoadAddonPack"] = "Skip loading addon pack at logout/quit: %q",
    ["keybind"] = keybindTexture,
    ["keybinds"] = keybindTexture .. " Keybinds",
    ["autoAddMissingDependencyAtPackLoad"] = "Automatically add missing dependencies to pack (at pack loading)",
    ["autoAddedMissingDependencyToPack"] = "Automatically added dependency %q to pack %q",


    --Official languages: This is translated by ZOs already! Only custom languages need to translate this
    --> Else: en.lu provides the translation for official languages!
    ["addons"] =                GetString(SI_GAME_MENU_ADDONS),
    ["libraries"] =             GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES),
    ["allCharacters"] =         GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL),
    ["singleCharName"]       =  GetString(SI_CURRENCYLOCATION0),
    ["disabledRed"] =           "|c990000" .. GetString(SI_SCREEN_NARRATION_TOGGLE_DISABLED) .."|r",
    ["missing"] =               "|cFF0000"..GetString(SI_GAMEPAD_ARMORY_MISSING_ENTRY_NARRATION).."|r",
    ["searchedForStr"]      =   "["..GetString(SI_SCREEN_NARRATION_EDIT_BOX_SEARCH_NAME).."]",
    ["ReloadUI"]            =   GetString(SI_ADDON_MANAGER_RELOAD) or "Reload UI",
    ["currently"] =             GetString(SI_COLOR_PICKER_CURRENT),
}


--[[ For the developers of unofficial language patches: English file lang/en.lua is loaded by default now!
If you want your own (debug) languages added (e.g. fx, or tb) please create your own <language>.lua file here in the lang folder
(copy existing file e.g. de.lua, any file EXCEPT en.lua!!! Never ever change or copy the en.lua file!!!)
]]

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    ZO_CreateStringId(stringId, strValue)
    SafeAddVersion(stringId, 1)
end
