local AS                            = AddonSelectorGlobal
AS.version                          = "3.00"
local ADDON_NAME	= AS.name
local addonNamePrefix = AS.addonNamePrefix

--ZOs speed-up variabes
local tos = tostring
local strfor = string.format
local strsub = string.sub
local strlow = string.lower

--Counters / numbers
local numbers = {
    numAddonsEnabled                 = 0,
    numAddonsTotal                   = 0,
}
AS.numbers = numbers

--Flags on/off
local flags = {
    AddedAddonsFragment = false,
    addonListWasOpenedByAddonSelector = false,
    wasSearchNextDoneByReturnKey = false,
    noAddonNumUpdate = false,
    noAddonCheckBoxUpdate = false,
    doNotReloadUI = false,
    preventOnClickDDL = false,
    skipUpdateDDL = false,
    wasLogoutPrehooked = false,
}
--Other AddOsns
flags.otherAddons = {
    isAddonCategoryEnabled = false, --AddonCategory
}
AS.flags = flags


--Current/Last data
local lastData = {
    selectedAddonSearchResult = {},
    lastChangedAddOnVars = {},
}
AS.lastData = lastData

--Search / Found data
local searchAndFoundData = {
    alreadyFound = {},
}
AS.searchAndFoundData = searchAndFoundData


--Utility
AS.utility = {}

--Constants
AS.constants = {}
local constants = AS.constants


--Currently loggedIn account info
constants.currentAccount = GetDisplayName()

--Currently loggedIn character info
local currentCharIdNum = GetCurrentCharacterId()
local currentCharId = tos(currentCharIdNum)
local currentCharName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))
constants.currentCharIdNum = currentCharIdNum
constants.currentCharId = currentCharId
constants.currentCharName = currentCharName



--SavedVariables
local savedVariablesConst = {
    svTableName = "AddonSelectorSavedVars",
    svVersion = 1,
    --===============================================
    defaultSavedVars  = {
        svMigrationToServerDone = false,
        -----------------------------------------------------
        addonPacks = {},
        addonPacksOfChar = {},
        autoReloadUI = false,
        selectAllSave = {},
        selectedPackNameForCharacters = {},
        showGlobalPacks = true,
        showSubMenuAtGlobalPacks = true,
        saveGroupedByCharacterName = false,
        showGroupedByCharacterName = false,
        searchExcludeFilename = false,
        searchSaveHistory = false,
        searchHistory = {},
        searchHistoryMaxEntries = 10,
        lastMassMarkingSavedProfile = nil,      --backup pack of enabled addons before mass-marking
        lastMassMarkingSavedProfileTime = nil,  --timeStamp of last saved backup before mass-marking
        lastLoadedPackNameForCharacters = {}, --charName, packName, and timestamp as the pack was loaded with a ReloadUI
        packChangedBeforeReloadUI = false,
        addPackTooltip = false,
        showPacksAddonList = false,
        showSearchFilterAtPacksList = true,
        showPacksOfOtherAccountsChars = true,
        packKeybinds = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
        },
        autoAddMissingDependencyAtPackLoad = false, --#16
    },
    --===============================================
    defaultSavedVarsChar = {
        loadAddonPackOnLogout = nil, --table with packName and charName
        skipLoadAddonPackOnLogout = false,
    },
}
constants.SavedVariables = savedVariablesConst
--AS.acwsv      Contains the accountWide settings
--AS.acwsvChar  Contains the per-character settings


--Constant for the global packs
local GLOBAL_PACK_NAME = "$G"
constants.GLOBAL_PACK_NAME = GLOBAL_PACK_NAME

--Constant for the charater saved packs
local CHARACTER_PACK_CHARNAME_IDENTIFIER = "_charName"
constants.CHARACTER_PACK_CHARNAME_IDENTIFIER = CHARACTER_PACK_CHARNAME_IDENTIFIER


local GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME = "$BACKUP_BEFORE_MASSMARK"
constants.GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME = GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME
local SEARCH_TYPE_NAME = "name"
constants.SEARCH_TYPE_NAME = SEARCH_TYPE_NAME

--Other Addons/Libraries which should not be disabled if you use the "disable all" keybind
--> see function AddonSelector_SelectAddons(false)
local addonsWhichShouldNotBeDisabled = {
    ["LibDialog"] =         true,
    ["LibCustomMenu"] =     true,
    ["LibScrollableMenu"] = true,
}
constants.addonsWhichShouldNotBeDisabled = addonsWhichShouldNotBeDisabled

--Settings that need to udate the dropdown entries at the combobox if setting is changed
local settingNeedsToUpdateDDL = {
    ["autoReloadUI"] = true,
    ["showPacksAddonList"] = true,
    ["addPackTooltip"] = true,
    ["showSearchFilterAtPacksList"] = true,
    ["showPacksOfOtherAccountsChars"] = true,
}
constants.settingNeedsToUpdateDDL = settingNeedsToUpdateDDL

--Do not disable mouse on these child conrols of AddonSelector, so one can still use them with all addons disabled
--via ZOs checkbox button
local isExcludedFromChangeEnabledState = {
    ["AddonSelectorSettingsOpenDropdown"] = true,
    ["AddonSelectorSearchBox"] = true,
}
constants.isExcludedFromChangeEnabledState = isExcludedFromChangeEnabledState


--Keybinds
constants.keybinds = {}
local MAX_ADDON_LOAD_PACK_KEYBINDS = 5
constants.keybinds.MAX_ADDON_LOAD_PACK_KEYBINDS = MAX_ADDON_LOAD_PACK_KEYBINDS


--Local speed-up reference variables
constants.ZOsControls = {
    ZOAddOns        =               ZO_AddOns,
    ZOAddOnsList    =               ZO_AddOnsList,
    enableAllAddonsParent =         ZO_AddOnsList2Row1,       --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow
    enableAllAddonTextCtrl =        ZO_AddOnsList2Row1Text,     --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow
    enableAllAddonsCheckboxCtrl =   ZO_AddOnsList2Row1Checkbox, --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow
}

--During layout changes clamp these controls to the screen
local controlsToSetClampedToScreen = {
    ZO_AddOns,
    ZO_AddOnsCurrentBindingsSaved,
    AddonSelectorStartAddonSearchButton,
    AddonSelectorToggleAddonStateButton,
    AddonSelectorSelectAddonsButton,
    AddonSelectorDeselectAddonsButton,
    ZO_AddOnsSecondaryButton,
    ZO_AddOnsPrimaryButton,
    ZO_AddOnsAdvancedUIErrors,
    ZO_AddOnsAdvancedUIErrors.label,
}
constants.ZOsControls.controlsToSetClampedToScreen = controlsToSetClampedToScreen


--Throttled Updater names
local updaterNames = {
    ASUpdateDDLThrottleName =           ADDON_NAME .. "_UpdateDDL_Updater",
    ASUpdateAddonCountThrottleName =    ADDON_NAME .. "_UpdateAddonCount_Updater",
    chatNarrationUpdaterName =          ADDON_NAME .. "_ChatNarration-",
    searchHistoryEventUpdaterName =     ADDON_NAME .. "_SearchHistory_Update",

}
constants.updaterNames = updaterNames


--Narration
local narration = {}
AS.narration = narration
--Do not narrate any text if mouse is moved above this control at ZO_AddOns
local ZOAddOns_BlacklistedNarrationChilds = {
    ["ZO_AddOnsTitle"]                      = true, --Title
    ["ZO_AddOnsSectionBar"]                 = true, --Top bar where Votans Addon List adds buttons to scroll to addons/libraries
    ["ZO_AddOnsList"]                       = true, --The scroll list with the addon rows
    ["ZO_AddOnsBGLeft"]                     = true, --The left background
    ["ZO_AddOnsDivider"]                    = true, --The divider
    ["ZO_AddOnsCharacterSelectDropdown"]    = true, --Character selection dropdown box
    ["AddOnSelector"]                       = true, --this addon here -> Will be added separately
    ["ZO_AddOnsAdvancedUIErrors"]           = true, --Enhanced UI errors: Checkbox & label
}
--Do not narrate any text if mouse is moved above this control at ZO_AddOns -> AddOnSelector
local ZOAddOns_AddonSelector_BlacklistedNarrationChilds = {
    ["AddonSelector"]                       = true,
    ["AddonSelectorEditBoxBG"]              = true,
    ["AddonSelectorSaveModeTexture"]        = true,
    ["AddonSelectorAutoReloadUITexture"]    = true,
    ["AddonSelectorBottomDivider"]          = true,
    ["AddonSelectorSearchBox"]              = true,
    ["AddonSelectorddl"]                    = true,
    ["AddonSelectorEditBox"]                = true,
    ["AddonSelectorSettingsOpenDropdown"]   = true,
}
AS.narration.blacklist = {
    ZOAddOns_BlacklistedNarrationChilds = ZOAddOns_BlacklistedNarrationChilds,
    ZOAddOns_AddonSelector_BlacklistedNarrationChilds = ZOAddOns_AddonSelector_BlacklistedNarrationChilds,
}

--LibScrollableMenu
local LSMconstants = {}
--LibScrollableMenu - Default contextMenu options
LSMconstants.defaultAddonPackMenuOptions = {
    visibleRowsDropdown = 15,
    visibleRowsSubmenu = 15,
    sortEntries = false,
    enableFilter        = function() return AS.acwsv.showSearchFilterAtPacksList end,
    headerCollapsible   = true,

    narrate = {
        ["OnComboBoxMouseEnter"] =  narration.narrateComboBoxOnMouseEnter,
        --["OnComboBoxMouseExit"] =   narration.narrateDropdownOnMouseExit,
        --["OnMenuShow"] =			narration.narrateDropdownOnOpened,
        --["OnMenuHide"] =			narration.narrateDropdownOnClosed,
        ["OnSubMenuShow"] =			narration.narrateDropdownOnSubmenuShown,
        ["OnSubMenuHide"] =		    narration.narrateDropdownOnSubmenuHidden,
        ["OnEntryMouseEnter"] =		narration.narrateDropdownOnEntryMouseEnter,
        --["OnEntryMouseExit"] =	narration.narrateDropdownOnEntryMouseExit,
        ["OnEntrySelected"] =		narration.narrateDropdownOnEntrySelected,
        ["OnCheckboxUpdated"] =		narration.narrateDropdownOnCheckboxUpdated,
    }
}
LSMconstants.defaultContextMenuOptions = {
    visibleRowsDropdown = 15,
    visibleRowsSubmenu  = 15,
    sortEntries         = false,
    enableFilter        = function() return AS.acwsv.showSearchFilterAtPacksList end,
    headerCollapsible   = true,
}
constants.LSM = LSMconstants


--Colors
local colors = {
    myDisabledColorDef = ZO_DISABLED_TEXT,
    charNamePackColorDef = ZO_ColorDef:New("C9B636"),

    charNamePackColorTemplate = "|cc9b636%s|r",
    globalPackColorTemplate = "|c7EC8E3%s|r",
    numAddonsColorTemplate = "|cf9a602%s|r",
    numLibrariesColorTemplate = "|cf9a602%s|r",
}
constants.colors = colors
local globalPackColorTemplate = colors.globalPackColorTemplate
local charNamePackColorTemplate = colors.charNamePackColorTemplate


--Textures
constants.textures = {}
local textures = AS.constants.textures
local reloadUITexture = "/esoui/art/miscellaneous/eso_icon_warning.dds"
textures.reloadUITexture = reloadUITexture
local reloadUITextureStr = "|cFF0000".. zo_iconFormatInheritColor(reloadUITexture, 24, 24) .."|r"
textures.reloadUITextureStr = reloadUITextureStr
textures.autoLoadOnLogoutTexture = "/esoui/art/buttons/log_out_up.dds"
--textures.autoLoadOnLogoutTextureStr = "|c00FF22".. zo_iconFormatInheritColor(autoLoadOnLogoutTexture, 24, 24) .."|r"


--Strings
--Boolean to on/off texts for narration
local booleanToOnOff = {
    [false] = GetString(SI_CHECK_BUTTON_OFF):upper(),
    [true]  = GetString(SI_CHECK_BUTTON_ON):upper(),
}
--Prefix strings for narration, based on e.g. ZO_Menu Owner control
local prefixStrings = {
    ["AddonSelectorSettingsOpenDropdown"] = AddonSelector_GetLocalizedText("settingPattern"),
    ["AddonSelectorSearchBox"] =            AddonSelector_GetLocalizedText("searchHistoryPattern"),
}

local packGlobalStr = AddonSelector_GetLocalizedText("packGlobal")
local allCharactersStr = AddonSelector_GetLocalizedText("allCharacters")
local singleCharNameStr = AddonSelector_GetLocalizedText("singleCharName")
local reloadUIStrWithoutIcon = strlow(AddonSelector_GetLocalizedText("ReloadUI"))
local addonSearchStr = AddonSelector_GetLocalizedText("AddonSearch")
local submenuStr = AddonSelector_GetLocalizedText("submenu")
local openedStr = AddonSelector_GetLocalizedText("openedStr")
local closedStr = AddonSelector_GetLocalizedText("closedStr")
local submenuOpenedStr = submenuStr .. " " .. openedStr
local submenuClosedStr = submenuStr .. " " .. closedStr
local stringConstants = {
    --tables
    prefixStrings =             prefixStrings,
    booleanToOnOff =            booleanToOnOff,

    --strings
    packGlobalStr =             packGlobalStr,
    packNameGlobal =            strfor(globalPackColorTemplate, packGlobalStr),
    allCharacters =             allCharactersStr,
    packNameCharacter =         strfor(charNamePackColorTemplate, allCharactersStr),
    singleCharNameStr =         singleCharNameStr,
    singleCharNameColoredStr =  strfor(charNamePackColorTemplate, singleCharNameStr),
    addonSearchStr =            addonSearchStr,
    searchMenuStr =             strsub(addonSearchStr, 1, -2), --remove last char,
    reloadUIStrWithoutIcon =    reloadUIStrWithoutIcon,
    reloadUIStr =               reloadUIStrWithoutIcon .. reloadUITextureStr,
    openedStr =                 openedStr,
    closedStr =                 closedStr,
    submenuOpenedStr =          submenuOpenedStr,
    submenuClosedStr =          submenuClosedStr,
}
constants.strings = stringConstants



--todo: Anything still needed here, which is not defined in en.lua? Add it there!
--[[
local addonsStr = GetString(SI_GAME_MENU_ADDONS)
local librariesStr = GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES)
local packNameCharacter = strfor(charNamePackColorTemplate, GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL))
local singleCharNameStr = AddonSelector_GetLocalizedText("singleCharName")
local singleCharNameColoredStr = strfor(charNamePackColorTemplate, singleCharNameStr)
local packGlobalStr = AddonSelector_GetLocalizedText("packGlobal")
local packNameGlobal = strfor(globalPackColorTemplate, packGlobalStr)
local packCharNameStr = AddonSelector_GetLocalizedText("packCharName")
local selectPackStr = AddonSelector_GetLocalizedText("selectPack")
local selectedPackNameStr = AddonSelector_GetLocalizedText("selectedPackName")
local deletePackAlertStr = AddonSelector_GetLocalizedText("deletePackAlert")
local deletePackErrorStr = AddonSelector_GetLocalizedText("deletePackError")
local deleteWholeCharacterPacksTitleStr = AddonSelector_GetLocalizedText("deleteWholeCharacterPacksTitle")
local deleteWholeCharacterPacksQuestionStr = AddonSelector_GetLocalizedText("deleteWholeCharacterPacksQuestion")
local savedGroupedByCharNameStr = AddonSelector_GetLocalizedText("SaveGroupedByCharacterName")
local autoReloadUIStr = AddonSelector_GetLocalizedText("autoReloadUIHint")
local searchMenuStr = AddonSelector_GetLocalizedText("AddonSearch")
searchMenuStr = strsub(searchMenuStr, 1, -2) --remove last char
local searchInstructions = AddonSelector_GetLocalizedText("searchInstructions")
local searchFound = AddonSelector_GetLocalizedText("foundSearch")
local searchFoundLast = AddonSelector_GetLocalizedText("foundSearchLast")
local searchedForStr = AddonSelector_GetLocalizedText("searchedForStr")
local clearSearchHistoryStr = AddonSelector_GetLocalizedText("searchClearHistory")
local reloadUIStrWithoutIcon = strlow(AddonSelector_GetLocalizedText("ReloadUI"))
local reloadUIStr = reloadUIStrWithoutIcon .. reloadUITextureStr
local deletePackTitleStr = AddonSelector_GetLocalizedText("deletePackTitle")
local selectSavedText = AddonSelector_GetLocalizedText("SelectAllAddonsSaved")
local overwriteSavePackStr = AddonSelector_GetLocalizedText("OverwriteSavePack")
local selectAllText = AddonSelector_GetLocalizedText("SelectAllAddons")
local packNameStr = AddonSelector_GetLocalizedText("packName")
local addonCategoriesStr = AddonSelector_GetLocalizedText("addonCategories")
local noCategoryStr = AddonSelector_GetLocalizedText("noCategory")
local currentTextStr = AddonSelector_GetLocalizedText("currentText")
local enDisableCurrentStateTemplateText = AddonSelector_GetLocalizedText("enDisableCurrentStateTemplate")
local enableText = AddonSelector_GetLocalizedText("enableText")
local disableText = AddonSelector_GetLocalizedText("disableText")
local stateText = AddonSelector_GetLocalizedText("stateText")
local newStateText = AddonSelector_GetLocalizedText("newStateText")
local libraryText = AddonSelector_GetLocalizedText("libraryText")
local openDropdownStr = AddonSelector_GetLocalizedText("openDropdownStr")
local openedStr = AddonSelector_GetLocalizedText("openedStr")
local closedStr = AddonSelector_GetLocalizedText("closedStr")
--local chosenStr = AddonSelector_GetLocalizedText("chosenStr")
local addPackTooltipStr = AddonSelector_GetLocalizedText("addPackTooltip")
local showPacksAddonListStr = AddonSelector_GetLocalizedText("showPacksAddonList")
local characterWideStr = AddonSelector_GetLocalizedText("characterWide")
local accountWideStr = AddonSelector_GetLocalizedText("accountWide")
local characterWidesStr = AddonSelector_GetLocalizedText("characterWides")
local accountWidesStr = AddonSelector_GetLocalizedText("accountWides")
local settingStr = AddonSelector_GetLocalizedText("settingPattern")
local currentlyStr = GetString(SI_COLOR_PICKER_CURRENT)
local searchHistoryStr = AddonSelector_GetLocalizedText("searchHistoryPattern")
local submenuStr = AddonSelector_GetLocalizedText("submenu")
local submenuOpenedStr = submenuStr .. " " .. openedStr
local submenuClosedStr = submenuStr .. " " .. closedStr
local entriesStr = AddonSelector_GetLocalizedText("entries")
local entryMouseEnterStr = AddonSelector_GetLocalizedText("entryMouseEnter")
local entrySelectedStr = AddonSelector_GetLocalizedText("entrySelected")
local checkboxStr = AddonSelector_GetLocalizedText("checkBox")
local enabledAddonsInPackStr = AddonSelector_GetLocalizedText("enabledAddonsInPack")
local addonsInPackStr = AddonSelector_GetLocalizedText("addonsInPack")
local librariesInPackStr = AddonSelector_GetLocalizedText("librariesInPack")
local showSearchFilterAtPacksListStr = AddonSelector_GetLocalizedText("showSearchFilterAtPacksList")
local disabledStr = AddonSelector_GetLocalizedText("disabledRed")
local missingStr = AddonSelector_GetLocalizedText("missing")
local otherAccStr = AddonSelector_GetLocalizedText("otherAccount")
local changedAddonPackStr = AddonSelector_GetLocalizedText("changedAddonPack")
local saveChangesNowStr = AddonSelector_GetLocalizedText("saveChangesNow")
local packNameLoadNotFoundStr = AddonSelector_GetLocalizedText("packNameLoadNotFound")
local packNameLoadFoundStr = AddonSelector_GetLocalizedText("packNameLoadFound")
local packNameLoadAtLogoutFoundStr = AddonSelector_GetLocalizedText("packNameLoadAtLogoutFound")
local addPackToKeybindStr = AddonSelector_GetLocalizedText("addPackToKeybind")
local removePackFromKeybindStr = AddonSelector_GetLocalizedText("removePackFromKeybind")
local loadOnLogoutOrQuitStr = AddonSelector_GetLocalizedText("loadOnLogoutOrQuit")
local skipLoadAddonPackStr = AddonSelector_GetLocalizedText("skipLoadAddonPack")
local autoAddMissingDependencyAtPackLoadStr = AddonSelector_GetLocalizedText("autoAddMissingDependencyAtPackLoad")
local autoAddedMissingDependencyToPackStr = AddonSelector_GetLocalizedText("autoAddedMissingDependencyToPack")
]]

--Controls
local asControls = { --these will be updated at EVENT_ADD_ON_LOADED etc.
    controlData = {
        firstControl == nil,
        firstControlData = nil,
        activeUpdateControlEvents = {},
    },

    --Single controls
    addonSelectorSelectAddonsButtonNameLabel = nil,
}
AS.controls = asControls

